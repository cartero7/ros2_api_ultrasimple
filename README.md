# ROS2 + FastAPI ultra simple

Ejemplo mínimo para probar una API REST que publica en un topic ROS2.

## Estructura

- `ros2_ws/src/demo_node`: paquete ROS2 en Python
- `api/main.py`: API FastAPI que publica en `/demo`

## Qué hace

- El nodo ROS2 `listener_node` se suscribe al topic `/demo` y muestra por consola lo que recibe.
- La API expone un endpoint `POST /send?msg=...` que publica mensajes en ese topic.

## Requisitos

- ROS2 instalado (por ejemplo Jazzy)
- Python con `fastapi` y `uvicorn`

Instalación rápida de dependencias Python:

```bash
python3 -m venv .venv --system-site-packages
source .venv/bin/activate
python -m pip install fastapi uvicorn
```

## Cómo usarlo

### 1) Compilar el workspace ROS2

```bash
cd ros2_ws
colcon build
source install/setup.bash
```

### 2) Lanzar el nodo ROS2 que escucha

En una terminal:

```bash
cd ros2_ws
source install/setup.bash
ros2 run demo_node listener_node
```

### 3) Lanzar la API

En otra terminal:

```bash
cd api
python3 main.py
```

O también:

```bash
cd api
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### 4) Probar

Desde el navegador o con curl:

Local:

```bash
curl -X POST "http://127.0.0.1:8001/send?msg=hola"
```

Desde otro equipo de la red:

```bash
curl -X POST "http://192.168.1.36:8001/send?msg=hola"
```

Respuesta esperada:

```json
{"status":"sent","msg":"hola"}
```

Y en la terminal del nodo ROS2 deberías ver algo como:

```text
Recibido por ROS2: hola
```

## Nota importante

La API inicializa un nodo ROS2 dentro de FastAPI y lanza un hilo en segundo plano con `rclpy.spin(...)`. Para un ejemplo real más grande, normalmente conviene separar mejor la capa API y la capa ROS2, pero para aprender esta versión es suficiente.

## Script rápido

Desde la raíz del proyecto:

```bash
chmod +x run_example.sh
./run_example.sh setup
```

Para lanzar todo con un solo comando:

```bash
./run_example.sh all
```

O por separado:

```bash
./run_example.sh listener
./run_example.sh api
```
