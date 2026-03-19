#!/usr/bin/env bash

set -eo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$ROOT_DIR/.venv"
ROS_WS_DIR="$ROOT_DIR/ros2_ws"
API_DIR="$ROOT_DIR/api"
ROS_SETUP="/opt/ros/jazzy/setup.bash"

usage() {
  cat <<'EOF'
Uso:
  ./run_example.sh setup
  ./run_example.sh listener
  ./run_example.sh api
  ./run_example.sh all

Comandos:
  setup     Crea el .venv si no existe, instala dependencias Python y compila ROS 2
  listener  Lanza el nodo ROS 2 que escucha en /demo
  api       Lanza la API FastAPI en http://0.0.0.0:8001
  all       Lanza listener en segundo plano y la API en primer plano
EOF
}

require_ros() {
  if [[ ! -f "$ROS_SETUP" ]]; then
    echo "No se encuentra ROS 2 en $ROS_SETUP"
    exit 1
  fi
}

setup_python() {
  if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR" --system-site-packages
  fi

  # FastAPI y uvicorn no vienen con ROS 2; los instalamos en el venv.
  source "$VENV_DIR/bin/activate"
  python -m pip install --upgrade pip
  python -m pip install fastapi uvicorn
}

build_workspace() {
  require_ros
  source "$ROS_SETUP"
  cd "$ROS_WS_DIR"
  colcon build
}

source_runtime() {
  require_ros
  source "$ROS_SETUP"

  if [[ ! -d "$VENV_DIR" ]]; then
    echo "Falta $VENV_DIR. Ejecuta primero: ./run_example.sh setup"
    exit 1
  fi

  source "$VENV_DIR/bin/activate"

  if [[ ! -f "$ROS_WS_DIR/install/setup.bash" ]]; then
    echo "Falta $ROS_WS_DIR/install/setup.bash. Ejecuta primero: ./run_example.sh setup"
    exit 1
  fi

  source "$ROS_WS_DIR/install/setup.bash"
}

run_listener() {
  source_runtime
  ros2 run demo_node listener_node
}

run_api() {
  source_runtime
  cd "$API_DIR"
  python main.py
}

run_all() {
  source_runtime
  ros2 run demo_node listener_node &
  listener_pid=$!

  cleanup() {
    if kill -0 "$listener_pid" >/dev/null 2>&1; then
      kill "$listener_pid" >/dev/null 2>&1 || true
      wait "$listener_pid" 2>/dev/null || true
    fi
  }

  trap cleanup EXIT INT TERM

  cd "$API_DIR"
  python main.py
}

main() {
  command="${1:-}"

  case "$command" in
    setup)
      setup_python
      build_workspace
      ;;
    listener)
      run_listener
      ;;
    api)
      run_api
      ;;
    all)
      run_all
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
