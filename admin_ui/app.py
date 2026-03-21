#!/usr/bin/env python3
import argparse
import glob
import os
import re
import shutil
import subprocess
import time
from collections import deque
from datetime import datetime
from functools import wraps
from pathlib import Path

from flask import Flask, Response, jsonify, render_template, request


MCS_SERVICE = os.getenv("MCS_SERVICE_NAME", "minecraft.service")
MCS_SERVER_DIR = os.getenv("MCS_SERVER_DIR", "/home/pi/mcs/mc_server")
BACKUP_DIR = os.getenv("MCS_BACKUP_DIR", "/home/pi/mcs/mcs_backup")
BACKUP_SCRIPT = os.getenv("MCS_BACKUP_SCRIPT", "/home/pi/mcs/mcs_backup/minecraft-backup.sh")
UPDATE_SCRIPT = os.getenv("MCS_UPDATE_SCRIPT", "/home/pi/mcs/mc_server/paperupdate.sh")
PLAYER_ACTIVITY_LOG = os.getenv("MCS_PLAYER_ACTIVITY_LOG", "/home/pi/mcs/player_activity.log")
MINECRAFT_LOG = os.getenv("MCS_MINECRAFT_LOG", f"{MCS_SERVER_DIR}/logs/latest.log")
SERVER_PROPERTIES = os.getenv("MCS_SERVER_PROPERTIES", f"{MCS_SERVER_DIR}/server.properties")
ACTION_LOG = os.getenv("MCS_ACTION_LOG", "/home/pi/mcs/admin/actions.log")
MCS_SCREEN_SESSION = os.getenv("MCS_SCREEN_SESSION", "minecraft_server")
ADMIN_USER = os.getenv("MCS_ADMIN_USER", "admin")
ADMIN_PASSWORD = os.getenv("MCS_ADMIN_PASSWORD", "")
ALLOW_HOST_POWER = os.getenv("MCS_ALLOW_HOST_POWER", "0") in {"1", "true", "TRUE", "yes", "YES"}

AUTH_ENABLED = bool(ADMIN_PASSWORD)

JOIN_RE = re.compile(r"]:\s([A-Za-z0-9_]{1,16}) joined the game$")
LEAVE_RE = re.compile(r"]:\s([A-Za-z0-9_]{1,16}) (left the game|lost connection: .*)$")
UUID_RE = re.compile(r"]:\sUUID of player ([A-Za-z0-9_]{1,16}) is ([0-9a-fA-F-]+)$")
LOGIN_RE = re.compile(r"]:\s([A-Za-z0-9_]{1,16})\[/[0-9a-fA-F\.:]+:\d+\] logged in with entity id")
COMMAND_RE = re.compile(r"]:\s([A-Za-z0-9_]{1,16}) issued server command:\s(/.*)$")
CHAT_RE = re.compile(r"]:\s(?:\[Not Secure\]\s)?<([^>]+)>\s(.*)$")
ERROR_RE = re.compile(r"(ERROR|WARN|Exception|Traceback|failed|Could not)", re.IGNORECASE)


app = Flask(__name__, template_folder=str(Path(__file__).with_name("templates")))


def run_command(cmd, timeout=20, cwd=None):
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=cwd)
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except subprocess.TimeoutExpired:
        return 124, "", f"Command timed out after {timeout}s: {' '.join(cmd)}"
    except FileNotFoundError:
        return 127, "", f"Command not found: {cmd[0]}"
    except Exception as exc:
        return 1, "", str(exc)


def run_background(cmd, label, cwd=None):
    Path(ACTION_LOG).parent.mkdir(parents=True, exist_ok=True)
    started = datetime.now().isoformat(timespec="seconds")
    with open(ACTION_LOG, "a", encoding="utf-8") as log_file:
        log_file.write(f"\n[{started}] START {label}: {' '.join(cmd)}\n")
        proc = subprocess.Popen(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            cwd=cwd,
            start_new_session=True,
            text=True,
        )
    return proc.pid


def auth_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if not AUTH_ENABLED:
            return func(*args, **kwargs)

        auth = request.authorization
        if not auth or auth.username != ADMIN_USER or auth.password != ADMIN_PASSWORD:
            return Response(
                "Authentication required",
                401,
                {"WWW-Authenticate": 'Basic realm="Pi-MCS Admin"'},
            )
        return func(*args, **kwargs)

    return wrapper


def read_last_lines(path, max_lines=200):
    if not Path(path).is_file():
        return []

    lines = deque(maxlen=max_lines)
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            lines.append(line.rstrip("\n"))
    return list(lines)


def service_state():
    _, out, _ = run_command(["systemctl", "is-active", MCS_SERVICE], timeout=5)
    return out or "unknown"


def service_uptime():
    _, pid_out, _ = run_command(["systemctl", "show", MCS_SERVICE, "--property=MainPID", "--value"], timeout=5)
    pid_str = pid_out.strip()
    if not pid_str.isdigit() or int(pid_str) <= 0:
        return "offline"
    _, up_out, _ = run_command(["ps", "-p", pid_str, "-o", "etime="], timeout=5)
    return up_out.strip() or "n/a"


def cpu_usage_percent():
    def sample():
        with open("/proc/stat", "r", encoding="utf-8") as f:
            parts = f.readline().split()[1:]
        values = [int(x) for x in parts]
        idle = values[3] + values[4]
        total = sum(values)
        return total, idle

    try:
        t1, i1 = sample()
        time.sleep(0.2)
        t2, i2 = sample()
        total_delta = t2 - t1
        idle_delta = i2 - i1
        if total_delta <= 0:
            return 0.0
        return round(100.0 * (1.0 - (idle_delta / total_delta)), 1)
    except Exception:
        return 0.0


def memory_stats():
    info = {}
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as f:
            for line in f:
                key, value = line.split(":", 1)
                info[key] = int(value.strip().split()[0])
    except Exception:
        return {"used_mb": 0, "total_mb": 0, "usage_percent": 0.0}

    total_kb = info.get("MemTotal", 0)
    available_kb = info.get("MemAvailable", 0)
    used_kb = max(total_kb - available_kb, 0)
    usage = (used_kb / total_kb * 100.0) if total_kb else 0.0
    return {
        "used_mb": round(used_kb / 1024, 1),
        "total_mb": round(total_kb / 1024, 1),
        "usage_percent": round(usage, 1),
    }


def disk_stats(path):
    try:
        st = os.statvfs(path)
        total = st.f_frsize * st.f_blocks
        free = st.f_frsize * st.f_bavail
        used = total - free
        usage = (used / total * 100.0) if total else 0.0
        return {
            "used_gb": round(used / (1024 ** 3), 2),
            "total_gb": round(total / (1024 ** 3), 2),
            "usage_percent": round(usage, 1),
        }
    except Exception:
        return {"used_gb": 0.0, "total_gb": 0.0, "usage_percent": 0.0}


def pi_temperature_c():
    if shutil.which("vcgencmd"):
        _, out, _ = run_command(["vcgencmd", "measure_temp"], timeout=5)
        match = re.search(r"temp=([0-9.]+)", out)
        if match:
            return float(match.group(1))

    temp_file = Path("/sys/class/thermal/thermal_zone0/temp")
    if temp_file.exists():
        try:
            raw = temp_file.read_text(encoding="utf-8").strip()
            return round(int(raw) / 1000.0, 1)
        except Exception:
            return None
    return None


def online_players():
    players = set()
    log_path = Path(MINECRAFT_LOG)
    if not log_path.exists():
        return []

    with open(log_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            match = JOIN_RE.search(line)
            if match:
                players.add(match.group(1))
                continue
            match = LEAVE_RE.search(line)
            if match:
                players.discard(match.group(1))

    return sorted(players)


def chat_lines(max_lines=150):
    lines = []
    for line in read_last_lines(MINECRAFT_LOG, max_lines=4000):
        if CHAT_RE.search(line):
            lines.append(line)
    return lines[-max_lines:]


def activity_lines(max_lines=150):
    lines = []
    for line in read_last_lines(MINECRAFT_LOG, max_lines=5000):
        if UUID_RE.search(line):
            lines.append(line)
            continue
        if JOIN_RE.search(line):
            lines.append(line)
            continue
        if LEAVE_RE.search(line):
            lines.append(line)
            continue
        if LOGIN_RE.search(line):
            lines.append(line)
            continue
        if COMMAND_RE.search(line):
            lines.append(line)
            continue
        if CHAT_RE.search(line):
            lines.append(line)
            continue
    return lines[-max_lines:]


def error_lines(max_lines=150):
    lines = [line for line in read_last_lines(MINECRAFT_LOG, max_lines=1200) if ERROR_RE.search(line)]
    return lines[-max_lines:]


def last_backup_info():
    backups = sorted(glob.glob(f"{BACKUP_DIR}/world_*.tar.gz"), key=os.path.getmtime, reverse=True)
    if not backups:
        return {"exists": False}

    backup = backups[0]
    stat = os.stat(backup)
    return {
        "exists": True,
        "file": os.path.basename(backup),
        "path": backup,
        "size_mb": round(stat.st_size / (1024 * 1024), 2),
        "mtime": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
    }


def current_status():
    mem = memory_stats()
    disk = disk_stats(MCS_SERVER_DIR)
    players = online_players()
    load1, load5, load15 = os.getloadavg()

    return {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "service_state": service_state(),
        "service_uptime": service_uptime(),
        "cpu_usage_percent": cpu_usage_percent(),
        "cpu_temp_c": pi_temperature_c(),
        "mem_used_mb": mem["used_mb"],
        "mem_total_mb": mem["total_mb"],
        "mem_usage_percent": mem["usage_percent"],
        "disk_used_gb": disk["used_gb"],
        "disk_total_gb": disk["total_gb"],
        "disk_usage_percent": disk["usage_percent"],
        "loadavg_1m": round(load1, 2),
        "loadavg_5m": round(load5, 2),
        "loadavg_15m": round(load15, 2),
        "players_online": players,
        "players_count": len(players),
        "last_backup": last_backup_info(),
        "auth_enabled": AUTH_ENABLED,
        "allow_host_power": ALLOW_HOST_POWER,
    }


def action_command(action_name):
    if action_name == "start_server":
        return {"mode": "sync", "cmd": ["sudo", "systemctl", "start", MCS_SERVICE]}
    if action_name == "stop_server":
        return {"mode": "sync", "cmd": ["sudo", "systemctl", "stop", MCS_SERVICE]}
    if action_name == "restart_server":
        return {"mode": "sync", "cmd": ["sudo", "systemctl", "restart", MCS_SERVICE]}
    if action_name == "backup_now":
        return {"mode": "background", "cmd": ["sudo", "bash", BACKUP_SCRIPT], "cwd": BACKUP_DIR}
    if action_name == "update_paper":
        return {"mode": "background", "cmd": ["sudo", "bash", UPDATE_SCRIPT], "cwd": MCS_SERVER_DIR}
    if action_name == "reboot_host" and ALLOW_HOST_POWER:
        return {"mode": "sync", "cmd": ["sudo", "systemctl", "reboot"]}
    if action_name == "shutdown_host" and ALLOW_HOST_POWER:
        return {"mode": "sync", "cmd": ["sudo", "systemctl", "poweroff"]}
    return None


def sanitize_console_input(text):
    cleaned = (text or "").replace("\r", " ").replace("\n", " ").strip()
    return cleaned[:500]


def send_to_minecraft_console(line):
    cmd = ["screen", "-S", MCS_SCREEN_SESSION, "-p", "0", "-X", "stuff", f"{line}\r"]
    code, out, err = run_command(cmd, timeout=5)
    if code != 0:
        details = err or out or "unknown error"
        return False, f"Failed to send to screen session '{MCS_SCREEN_SESSION}': {details}"
    return True, "sent"


def print_summary():
    status = current_status()
    backup = status["last_backup"]
    backup_text = "none"
    if backup.get("exists"):
        backup_text = f"{backup['file']} ({backup['mtime']}, {backup['size_mb']} MB)"

    print("=== Pi-MCS Admin Summary ===")
    print(f"Time:            {status['timestamp']}")
    print(f"Service state:   {status['service_state']}")
    print(f"Service uptime:  {status['service_uptime']}")
    print(f"Players online:  {status['players_count']} -> {', '.join(status['players_online']) or '-'}")
    print(f"CPU usage:       {status['cpu_usage_percent']} %")
    print(f"CPU temp:        {status['cpu_temp_c']} C")
    print(f"RAM usage:       {status['mem_used_mb']} / {status['mem_total_mb']} MB ({status['mem_usage_percent']} %)")
    print(f"Disk usage:      {status['disk_used_gb']} / {status['disk_total_gb']} GB ({status['disk_usage_percent']} %)")
    print(
        f"Load avg:        {status['loadavg_1m']} / {status['loadavg_5m']} / {status['loadavg_15m']}"
    )
    print(f"Last backup:     {backup_text}")


@app.get("/")
@auth_required
def index():
    return render_template("index.html", auth_enabled=AUTH_ENABLED, allow_host_power=ALLOW_HOST_POWER)


@app.get("/api/status")
@auth_required
def api_status():
    return jsonify(current_status())


@app.get("/api/logs/<log_type>")
@auth_required
def api_logs(log_type):
    if log_type == "errors":
        lines = error_lines(max_lines=200)
    elif log_type == "activity":
        lines = activity_lines(max_lines=300)
        if not lines:
            lines = read_last_lines(PLAYER_ACTIVITY_LOG, max_lines=200)
    elif log_type == "chat":
        lines = chat_lines(max_lines=200)
    elif log_type == "service":
        _, out, err = run_command(["journalctl", "-u", MCS_SERVICE, "-n", "200", "--no-pager"], timeout=10)
        text = out if out else err
        lines = text.splitlines()
    elif log_type == "latest":
        lines = read_last_lines(MINECRAFT_LOG, max_lines=200)
    else:
        return jsonify({"error": "unknown log type"}), 400
    return jsonify({"log_type": log_type, "lines": lines})


@app.get("/api/server-properties")
@auth_required
def api_server_properties():
    prop_path = Path(SERVER_PROPERTIES)
    if not prop_path.exists():
        return jsonify({"error": f"{SERVER_PROPERTIES} not found"}), 404
    content = prop_path.read_text(encoding="utf-8", errors="ignore")
    return jsonify({"content": content})


@app.post("/api/server-properties")
@auth_required
def api_server_properties_save():
    payload = request.get_json(silent=True) or {}
    content = payload.get("content")
    if content is None:
        return jsonify({"error": "missing 'content' field"}), 400

    prop_path = Path(SERVER_PROPERTIES)
    if not prop_path.exists():
        return jsonify({"error": f"{SERVER_PROPERTIES} not found"}), 404

    backup_path = f"{SERVER_PROPERTIES}.bak-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    shutil.copy2(SERVER_PROPERTIES, backup_path)
    prop_path.write_text(content, encoding="utf-8")
    return jsonify({"ok": True, "backup_file": backup_path})


@app.post("/api/console")
@auth_required
def api_console():
    payload = request.get_json(silent=True) or {}
    mode = (payload.get("mode") or "").strip().lower()
    message = sanitize_console_input(payload.get("message"))

    if mode not in {"chat", "command"}:
        return jsonify({"error": "mode must be 'chat' or 'command'"}), 400
    if not message:
        return jsonify({"error": "message is empty"}), 400
    if service_state() != "active":
        return jsonify({"error": "minecraft service is not active"}), 409

    if mode == "chat":
        line = f"say [WEB] {message}"
    else:
        line = message if message.startswith("/") else f"/{message}"

    ok, detail = send_to_minecraft_console(line)
    if not ok:
        return jsonify({"ok": False, "error": detail}), 500

    return jsonify({"ok": True, "mode": mode, "sent": line})


@app.post("/api/action/<action_name>")
@auth_required
def api_action(action_name):
    action = action_command(action_name)
    if action is None:
        return jsonify({"error": "action not allowed or unknown"}), 400

    if action["mode"] == "background":
        pid = run_background(action["cmd"], action_name, cwd=action.get("cwd"))
        return jsonify({"ok": True, "started": True, "pid": pid, "action": action_name})

    code, out, err = run_command(action["cmd"], timeout=30, cwd=action.get("cwd"))
    return jsonify(
        {
            "ok": code == 0,
            "action": action_name,
            "returncode": code,
            "stdout": out,
            "stderr": err,
        }
    )


def main():
    parser = argparse.ArgumentParser(description="Pi-MCS Admin Tool")
    parser.add_argument("--summary", action="store_true", help="Print a terminal status summary and exit.")
    parser.add_argument("--host", default=os.getenv("MCS_ADMIN_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.getenv("MCS_ADMIN_PORT", "8080")))
    args = parser.parse_args()

    if args.summary:
        print_summary()
        return

    app.run(host=args.host, port=args.port, debug=False)


if __name__ == "__main__":
    main()
