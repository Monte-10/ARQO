import subprocess
import numpy as np
import matplotlib.pyplot as plt

# Rutas de los ejecutables (ajústalas según tus rutas)
path_serie = './pescalar_serie'
path_par = './pescalar_par4'

# Rango de tamaños de vector para probar
vector_sizes = np.arange(5000, 20000, 1000)

# Función para ejecutar un programa y obtener el tiempo de ejecución
def run_program(program_path, vector_size):
    result = subprocess.run([program_path, str(vector_size)], capture_output=True, text=True)
    output = result.stdout.splitlines()
    for line in output:
        if line.startswith("Tiempo"):
            return float(line.split(":")[1].strip())
    return None

# Almacenar los tiempos de ejecución
times_serie = []
times_par = []

# Ejecutar los programas y recoger los tiempos
for size in vector_sizes:
    time_serie = run_program(path_serie, size)
    time_par = run_program(path_par, size)
    times_serie.append(time_serie)
    times_par.append(time_par)

# Gráfica de los tiempos de ejecución
plt.plot(vector_sizes, times_serie, label='Serie')
plt.plot(vector_sizes, times_par, label='Paralelo')
plt.xlabel('Tamaño del Vector')
plt.ylabel('Tiempo de Ejecución (s)')
plt.title('Comparación de Tiempos de Ejecución Serie vs Paralelo')
plt.legend()
plt.show()
