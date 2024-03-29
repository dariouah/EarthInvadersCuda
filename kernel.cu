#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <conio.h>
#include <atomic>
#include <iostream>
#include <thread>
#include <chrono>
#include <curand_kernel.h>
#include <windows.h>

#define RESET   "\033[0m"
#define GREEN   "\033[1m\033[32m"
#define ORANGE  "\033[38;5;208m"
#define BLUE    "\033[1m\033[34m"
#define PINK    "\033[1m\033[35m"
#define YELLOW  "\033[1m\033[33m"
#define RED     "\033[1m\033[31m"

// Configuracion grid
const int dimBlock = 16;

// Constantes de objetos
const char JUGADOR = 'W';
const char ALIEN = 'A';
const char NUBE = 'N';
const char CEFALOPODO = 'C';
const char DESTRUCTOR = 'D';
const char CRUCERO = 'R';
const char COMANDANTE = 'X';
const char MURO = 'B';

// Constantes de probabilidades
int ALIEN_PROB = 40;
int NUBE_PROB = 25;
int CEFALOPODO_PROB = 15;
int DESTRUCTOR_PROB = 5;
int CRUCERO_PROB = 13;
int COMANDANTE_PROB = 2;
const int MURO_PROB = 15;

// Conversion de probabilidades
// Con la generacion de numeros aleatorios, se compara con estas constantes para saber que objeto se genera
const int ALIEN_CONV = 40;
const int NUBE_CONV = 65;
const int CEFALOPODO_CONV = 80;
const int DESTRUCTOR_CONV = 85;
const int CRUCERO_CONV = 98;
const int COMANDANTE_CONV = 100;

// Constantes de puntajes
const int ALIEN_PUNT = 5;
const int NUBE_PUNT = 25;
const int CEFALOPODO_PUNT = 15;
const int DESTRUCTOR_PUNT = 5;
const int CRUCERO_PUNT = 13;
const int COMANDANTE_PUNT = 100;

// Constantes de otros
const int MURO_ALTURA = 5;
const int VIDA_INICIO = 5;
const int RONDA_TIEMPO = 2;
const int TAM_ONDA = 5;

using namespace std;

__global__ void generarTablero(char* tablero, int numFils, int numCols, unsigned int seed) {
    // Índice global del hilo
    int fila = (blockIdx.x * blockDim.x) + threadIdx.x;
    int columna = (blockIdx.y * blockDim.y) + threadIdx.y;
    int idx = fila * numCols + columna;

    // Comprobar que el índice esté dentro del tamaño del tablero
    if (fila < numFils && columna < numCols) {
        // Inicializar el generador de números aleatorios para este hilo con la semilla proporcionada
        curandState_t state;
        curand_init(seed + idx, idx, 0, &state);

        // Comprobamos si estamos en la fila adecuada para generar muros
        if (fila == (numFils - 5)) {
            // Generar un número aleatorio entre 0 y 99
            int rand_num = curand(&state) % 100;

            // Comprobar si se cumple la probabilidad de generar un muro
            if (rand_num < MURO_PROB) {
                // Contador para rastrear muros consecutivos
                __shared__ int murosSeguidos;
                murosSeguidos = 0;
                __syncthreads();

                // Generar muro o espacio vacío según las condiciones
                if (murosSeguidos < 3) {
                    tablero[idx] = 'B';
                    atomicAdd(&murosSeguidos, 1);
                }
                else {
                    tablero[idx] = ' ';
                }
            }
            else {
                tablero[idx] = ' '; // Espacio vacío si no se cumple la probabilidad
            }
        }
        else {
            tablero[idx] = ' '; // Espacio vacío en otras filas
        }
    }

}

// Función para mostrar el marco alrededor de la vida y la puntuación
void mostrarPuntuacion(int vida, int puntuacion, int numCols) {
    // Determinar el ancho del marco según el número de columnas del tablero
    int anchoMarco = numCols + 12; // El marco tendrá un ancho adicional de 12 caracteres

    // Mostrar el marco superior
    printf("+");
    for (int i = 0; i < anchoMarco - 2; ++i) {
        printf("-");
    }
    printf("+\n");

    // Mostrar la vida y la puntuación dentro del marco
    printf("| Vida: %3d    Puntuacion: %5d |\n", vida, puntuacion);

    // Mostrar el marco inferior
    printf("+");
    for (int i = 0; i < anchoMarco - 2; ++i) {
        printf("-");
    }
    printf("+\n");
}

// Función para mostrar el tablero
void mostrarTablero(char* tablero, int numFils, int numCols) {

    // Mostrar el tablero por CPU (solo es un hilo)
    for (int i = 0; i < numFils; i++) {
        for (int j = 0; j < numCols; j++) {
            char alien = tablero[i * numCols + j];
            switch (alien) {
            case 'A':
                printf(GREEN "[%c]" RESET, alien); // Alienígena – verde
                break;
            case 'N':
                printf(ORANGE "[%c]" RESET, alien); // Nube – naranja
                break;
            case 'C':
                printf(BLUE "[%c]" RESET, alien); // Cefalópodo – azul
                break;
            case 'D':
                printf(PINK "[%c]" RESET, alien); // Destructor – rosa
                break;
            case 'R':
                printf(YELLOW "[%c]" RESET, alien); // Crucero – amarillo
                break;
            case 'X':
                printf(RED "[%c]" RESET, alien); // Comandante – rojo
                break;
            default:
                printf("[%c]", alien); // Otros caracteres
            }
        }
        printf("\n");
    }
    printf("\n");
}


__global__ void reconversion(char* origenTablero, char* destinoTablero, int numFils, int numCols, unsigned int seed)
{
    int fila = (blockIdx.x * blockDim.x) + threadIdx.x;
    int columna = (blockIdx.y * blockDim.y) + threadIdx.y;
    int idx = fila * numCols + columna;
    curandState_t state;

    if (fila < numFils && columna < numCols) {
        char celdaOrigen = origenTablero[idx];
        // Clonamos el tablero en el destino
        destinoTablero[idx] = celdaOrigen;

        char resultado = 'N';
        int idxEncima = (fila - 1)* numCols + columna;
        int idxDebajo = idxDebajo = (fila + 1) * numCols + columna;
        int idxIzquierda = idxIzquierda = fila * numCols + (columna - 1);
        int idxDerecha = idxDerecha = fila * numCols + (columna + 1);

        // Comprobacion para hacer conversiones de alienigenas
        if (celdaOrigen == 'N' || celdaOrigen == 'A') {
            if (fila > 0 && fila < (numFils - 1) && columna>0 && columna < (numCols - 1)) {
                // Cambios el resultado por defecto si es una nube
                if (celdaOrigen == 'N') {
                    resultado = 'C';
                }
                if (origenTablero[idxEncima] == 'A' && origenTablero[idxDebajo] == 'A' && origenTablero[idxIzquierda] == 'A' && origenTablero[idxDerecha] == 'A') {
                    destinoTablero[idxEncima] = ' ';
                    destinoTablero[idxDebajo] = ' ';
                    destinoTablero[idxIzquierda] = ' ';
                    destinoTablero[idxDerecha] = ' ';
                    destinoTablero[idx] = resultado;

                }
            }
        } 
        else if (celdaOrigen == 'X') {
            curand_init(seed + idx, idx, 0, &state); // 1234 es una semilla, se puede cambiar
            if (fila > 0 && fila < (numFils - 1) && columna > 0 && columna < (numCols - 1)) {
                // Generar número aleatorio
                int aleatorio = curand(&state) % 100;
                if (aleatorio < 10) {
                    // Generar alienígenas en las posiciones adyacentes
                    destinoTablero[idxEncima] = ' ';
                    destinoTablero[idxDebajo] = ' ';
                    destinoTablero[idxIzquierda] = ' ';
                    destinoTablero[idxDerecha] = ' ';
                }
            }
        }
    }
}

__global__ void descenso(char* origenTablero, char* destinoTablero, int numFils, int numCols)
{
    int fila = (blockIdx.x * blockDim.x) + threadIdx.x;
    int columna = (blockIdx.y * blockDim.y) + threadIdx.y;
    int idx = fila * numCols + columna;

    if (fila < (numFils - 1) && columna < numCols) {
        char celdaOrigen = origenTablero[idx];
        char celdaDestino = origenTablero[idx + numCols];

        // Debemos de considerar los casos donde el destino sea un muro
        if (celdaDestino == 'B') {

            // Si la celda de origen es un destructor, indicamos que choca con muro
            if (celdaOrigen == 'D') {
                destinoTablero[idx + numCols] = 'd';

            }
            // Si la celda de origen es un crucero, rompe el muro
            else if (celdaOrigen == 'R') {
                destinoTablero[idx + numCols] = 'r';
            }
            // Si la celda de origen es un comandante, rompe el muro
            else if (celdaOrigen == 'X') {
                destinoTablero[idx + numCols] = 'X';
            }
            else {
                destinoTablero[idx + numCols] = 'B';
            }
            destinoTablero[idx + 2 * numCols] = ' ';
        }
        else if (celdaDestino == 'W') {
            
            if (celdaOrigen == ' ') {
                destinoTablero[idx + numCols] = 'W';
            }
            else {
                destinoTablero[idx + numCols] = '-';
			}
        }
        else {
            if (celdaOrigen != 'B') {
                destinoTablero[idx + numCols] = celdaOrigen;
            }
        }
    }
}

__global__ void generacion(char* origenTablero, char* destinoTablero, int numFils, int numCols, int* bolsaAleatorios)
{
    int fila = (blockIdx.x * blockDim.x) + threadIdx.x;
    int columna = (blockIdx.y * blockDim.y) + threadIdx.y;
    int idx = fila * numCols + columna;

    if (fila == 0 && columna < numCols) {
        int aleatorio = bolsaAleatorios[columna];
        if (aleatorio < ALIEN_CONV) {
            destinoTablero[idx] = ALIEN;
        }
        else if (aleatorio < NUBE_CONV) {
            destinoTablero[idx] = NUBE;
        }
        else if (aleatorio < CEFALOPODO_CONV) {
            destinoTablero[idx] = CEFALOPODO;
        }
        else if (aleatorio < DESTRUCTOR_CONV) {
            destinoTablero[idx] = DESTRUCTOR;
        }
        else if (aleatorio < CRUCERO_CONV) {
            destinoTablero[idx] = CRUCERO;
        }
        else if (aleatorio < COMANDANTE_CONV) {
            destinoTablero[idx] = COMANDANTE;
        }
        else {
            destinoTablero[idx] = ' ';
        }
    }
}

__global__ void desintegracion(char* origenTablero, char* destinoTablero, int numFils, int numCols, int* puntuacion, int* vida, unsigned int seed)
{
    int fila = (blockIdx.x * blockDim.x) + threadIdx.x;
    int columna = (blockIdx.y * blockDim.y) + threadIdx.y;
    int idx = fila * numCols + columna;
    curandState_t state;

    // Id de hilo pertenezca al tablero y no es la ultima fila
    if (fila < numFils && columna < numCols) {
        char celdaOrigen = origenTablero[idx];
        // Clonamos el tablero en el destino
        destinoTablero[idx] = celdaOrigen;

        // Id de hilo pertenece a ultima fila, actualiza puntuaciones
        if (fila == (numFils - 1)) {
            if (celdaOrigen == ALIEN) {
                atomicAdd(puntuacion, ALIEN_PUNT);
            }
            else if (celdaOrigen == NUBE) {
                atomicAdd(puntuacion, NUBE_PUNT);
            }
            else if (celdaOrigen == CEFALOPODO) {
                atomicAdd(puntuacion, CEFALOPODO_PUNT);
            }
            // Si el destructor hubiese chocado con jugador, seria 'd' y no contaría puntuación
            else if (celdaOrigen == DESTRUCTOR) {
                atomicAdd(puntuacion, DESTRUCTOR_PUNT);
            }
            else if (celdaOrigen == CRUCERO) {
                atomicAdd(puntuacion, CRUCERO_PUNT);
            }
            else if (celdaOrigen == COMANDANTE) {
                atomicAdd(puntuacion, COMANDANTE_PUNT);
                atomicAdd(vida, 1);
            }
            // Solo mantenemos el jugador
            if (celdaOrigen!='d' && celdaOrigen!='W' && celdaOrigen != '-') {
			    destinoTablero[idx] = ' ';
			}
            // Si fue golpeado en descenso, lo tomamos en cuenta
            else if (celdaOrigen == '-') {
				destinoTablero[idx] = 'W';
                atomicSub(vida, 1);
			}
        }

        // Si la celda es un destructor, generamos la onda expansiva
        if (celdaOrigen == 'd' || (celdaOrigen == 'D' && fila == numFils-1)) {
            // Inicio del cuadrado de onda expansiva
            int filaIni = fila - TAM_ONDA;
            int columnaIni = columna - TAM_ONDA;
            // Cuadrado de onda expansiva
            for (int i = filaIni; i < filaIni + (TAM_ONDA * 2 + 1); i++) {
				for (int j = columnaIni; j < columnaIni + (TAM_ONDA * 2 + 1); j++) {
                    // Comprobamos que la celda pertenezca al tablero
					if (i >= 0 && i < numFils && j >= 0 && j < numCols) {
                        char impacto = origenTablero[i * numCols + j];
                        // Si la onda golpea al jugador, se resta vida
                        if (impacto == 'W' || impacto == '-') {
                            atomicSub(vida, 1);
						}
                        // La onda no puede destruir ni muros, ni otros destructores y cruceros pendientes de desintegracion
                        else if (impacto != 'B' && impacto != 'd' && impacto != 'r' && impacto != '-') {
							destinoTablero[i * numCols + j] = ' ';
                        }
					}
				}
            }
            // Tras las explosiones, recuperamos los muros
            if (celdaOrigen == 'd') {
				destinoTablero[idx] = 'B';
            }
        }

        // Si la celda es un crucero, generamos la onda expansiva
        if (celdaOrigen == 'r' || (celdaOrigen == 'R' && fila == numFils - 1)) {
            curand_init(seed + idx, 0, 0, &state);
            int aleatorio = curand(&state) % 2;
            int ondaIni;
            int ondaFin;
            int ondaInc;

            // Inicio del cuadrado de onda expansiva
            if (aleatorio == 0) {
                ondaIni = fila * numCols;
				ondaFin = fila * (numCols + 1);
				ondaInc = 1;
			}
			else {
				ondaIni = columna;
				ondaFin = numFils * numCols + columna;
				ondaInc = numCols; 
            }

            // Recorremos la onda
            for (int i = ondaIni; i < ondaFin; i += ondaInc) {
                // Comprobamos que la celda pertenezca al tablero
                char impacto = origenTablero[i];
                // Si golpea al jugador, se pone como jugador dañado
                if (impacto == 'W' || impacto == '-') {
                    atomicSub(vida, 1);
                }
                // No tenemos en consideracion el muro porque puede romperlo
                else if (impacto != 'd' && impacto != 'r' && impacto != '-') {
                    destinoTablero[i] = ' ';
                }
            }

            // Tras las explosiones, desintegramos la nave
            if (celdaOrigen == 'r') {
                destinoTablero[idx] = ' ';  
            }
        }
    }
}

int main() {

    // Inicializamos por defecto
    int numFils = 15;
    int numCols = 10;
    char ejecucion = 'm';
    int puntuacion = 0;
    int vida = VIDA_INICIO;
    char caracter;
    int posJugador;
    bool incorrecto = false;
    // Inicializacion de la semilla para los numeros aleatorios
    srand(time(NULL));


    // Solicitar al usuario que ingrese los valores
    printf("+-------------------------------------------------+\n");
    printf("|               Configuracion Inicial             |\n");
    printf("+-------------------------------------------------+\n");
    printf("| Por favor, ingrese la configuracion inicial:    |\n");
    printf("|-------------------------------------------------|\n");
    printf("| Numero de filas (>=15): ");
    scanf("%d", &numFils);
    // Limpiar el búfer de entrada para evitar problemas
    while (getchar() != '\n');

    printf("| Numero de columnas (>=10): ");
    scanf("%d", &numCols);
    // Limpiar el búfer de entrada para evitar problemas
    while (getchar() != '\n');

    printf("| Modo de ejecucion (<m>, <a>): ");
    // Leer el carácter desde la entrada estándar
    scanf(" %c", &ejecucion);
    // Limpiar el búfer de entrada para evitar problemas
    while (getchar() != '\n');

    // Comprobamos los valores introducidos
    if (numFils < 15 || numCols < 10 || (ejecucion != 'm' && ejecucion != 'a')) {
        printf("+-------------------------------------------------+\n");
        printf("|              Configuracion Incorrecta           |\n");
        printf("+-------------------------------------------------+\n");
        printf("| Valores introducidos incorrectos. Se elegiran    \n");
        printf("| valores predeterminados:                         \n");
        printf("| Numero de filas: 15\n");
        printf("| Numero de columnas: 10\n");
        printf("| Modo de ejecucion: m\n");
        printf("+-------------------------------------------------+\n");

        // Valores por defecto
        numFils = 15;
        numCols = 10;
        ejecucion = 'm';
        incorrecto = true;
    }

    // Reservamos memoria en device para las matrices que usaremos en la GPU
    char* origenTablero;
    char* destinoTablero;
    cudaMalloc((void**)&origenTablero, numFils * numCols * sizeof(char));
    cudaMalloc((void**)&destinoTablero, numFils * numCols * sizeof(char));

    // Configuración de la cuadrícula y los bloques
    dim3 threadsPerBlock(dimBlock, dimBlock);
    int altoGrid = (numFils + threadsPerBlock.x - 1) / threadsPerBlock.x;
    int anchoGrid = (numCols + threadsPerBlock.y - 1) / threadsPerBlock.y;
    dim3 numBlocks(altoGrid, anchoGrid);

    // Mostrar mensaje decorado
    if (incorrecto) {
        printf("\n\n\n\n\n\n\n\n\n");
    } else {
		printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
    }
    printf("+-------------------------------------------------+\n");
    printf("|            Presione Enter para continuar        |\n");
    printf("+-------------------------------------------------+\n");
    getchar(); // Esperar a que el usuario presione Enter


    // Inicializamos tablero que usaremos en la CPU
    char* tableroCPU;
    tableroCPU = new char[numFils * numCols];
    // Llamada al kernel generarTablero para origenTablero
    generarTablero << <numBlocks, threadsPerBlock >> > (origenTablero, numFils, numCols, time(NULL));
    // Copiamos el tablero a la CPU
    cudaMemcpy(tableroCPU, origenTablero, numFils * numCols * sizeof(char), cudaMemcpyDeviceToHost);

    // Añadimos posicion del jugador
    posJugador = numCols / 2;
    tableroCPU[(numFils - 1) * numCols + posJugador] = 'W';

    // Comenzamos el juego
    while (vida>0) {
        
        // Limpiamos la pantalla
        printf("\n\n\n\n\n\n\n\n\n");
        // Mostramos la vida y la puntuacion
        mostrarPuntuacion(vida, puntuacion, 22);
        // Mostramos el tablero
        mostrarTablero((char*)tableroCPU, numFils, numCols);

        //Aseguramos movimiento del jugador
        bool salir = false;
        // Buscamos pulsacion hasta que implique movimiento
        while (!salir) {
            // Comprobamos el modo de ejecucion
            if (ejecucion == 'm') {
                caracter = _getch();
            }
            else {
                // Generamos un movimiento aleatorio
                Sleep(1000);
                if ((rand() % 2) == 0) {
                    caracter = 'A';
                }
                else {
                    caracter = 'D';
                }  
            }

            if (caracter == 'a' || caracter == 'A') {
                salir = true;
                if (posJugador > 0) {
                    tableroCPU[(numFils - 1)*numCols+posJugador] = ' ';
                    posJugador--;
                    tableroCPU[(numFils - 1) * numCols + posJugador] = 'W';
                }
            }
            else if (caracter == 'd' || caracter == 'D') {
                salir = true;
                if (posJugador < numCols - 1) {
                    tableroCPU[(numFils - 1) * numCols + posJugador] = ' ';
                    posJugador++;
                    tableroCPU[(numFils - 1) * numCols + posJugador] = 'W';
                }
            }
        }

        // Actualizamos el tablero
        cudaMemcpy(origenTablero, tableroCPU, numFils * numCols * sizeof(char), cudaMemcpyHostToDevice);

        // Llamada al kernel reconversion
        reconversion << <numBlocks, threadsPerBlock >> > (origenTablero, destinoTablero, numFils, numCols, time(NULL));
        cudaMemcpy(origenTablero, destinoTablero, numFils * numCols * sizeof(char), cudaMemcpyDeviceToDevice);

        // Llamada al kernel descenso
        descenso << <numBlocks, threadsPerBlock >> > (origenTablero, destinoTablero, numFils, numCols);
        cudaMemcpy(origenTablero, destinoTablero, numFils * numCols * sizeof(char), cudaMemcpyDeviceToDevice);

        // Preparacion llamada al kernel generacion
        // Generamos un numero aleatorio para cada celda de la primera fila
        int* bolsaAleatoriosCPU;
        bolsaAleatoriosCPU = new int[numCols];
        for (int i = 0; i < numCols; i++) {
			bolsaAleatoriosCPU[i] = rand() % 100;
		}
        // Inicializamos el array de aleatorios en la GPU
        int* bolsaAleatoriosGPU;
        cudaMalloc((void**)&bolsaAleatoriosGPU, numFils * numCols * sizeof(char));
        cudaMemcpy(bolsaAleatoriosGPU, bolsaAleatoriosCPU, numFils * numCols * sizeof(char), cudaMemcpyHostToDevice);
        // Llamada al kernel generacion
        generacion << <numBlocks, threadsPerBlock >> > (origenTablero, destinoTablero, numFils, numCols, bolsaAleatoriosGPU);
        cudaMemcpy(origenTablero, destinoTablero, numFils * numCols * sizeof(char), cudaMemcpyDeviceToDevice);

        // Preracion llamada al kernel desintegracion
        int* puntuacionGPU;
        int* vidaGPU;
        cudaMalloc((void**)&puntuacionGPU, sizeof(int));
        cudaMalloc((void**)&vidaGPU, sizeof(int));
        cudaMemcpy(puntuacionGPU, &puntuacion, sizeof(int), cudaMemcpyHostToDevice);
        cudaMemcpy(vidaGPU, &vida, sizeof(int), cudaMemcpyHostToDevice);
        // Llamamos al kernel desintegracion
        desintegracion << <numBlocks, threadsPerBlock >> > (origenTablero, destinoTablero, numFils, numCols, puntuacionGPU, vidaGPU, time(NULL));
        cudaMemcpy(origenTablero, destinoTablero, numFils * numCols * sizeof(char), cudaMemcpyDeviceToDevice);

        // Mostramos la vida y la puntuacion
        cudaMemcpy(&puntuacion, puntuacionGPU, sizeof(int), cudaMemcpyDeviceToHost); // Copia la puntuacion al dispositivo
        cudaMemcpy(&vida, vidaGPU, sizeof(int), cudaMemcpyDeviceToHost); // Copia la vida al dispositivo
        // Comprobamos al final del ciclo
        cudaMemcpy(tableroCPU, destinoTablero, numFils * numCols * sizeof(char), cudaMemcpyDeviceToHost);
    }

    // Mostramos la vida y la puntuacion
    mostrarPuntuacion(vida, puntuacion, 22);
    // Mostramos el tablero
    mostrarTablero((char*)tableroCPU, numFils, numCols);


    printf("+-------------------------------------------------+\n");
    printf("|               HAS SIDO DERROTADO                |\n", puntuacion);
    printf("+-------------------------------------------------+\n");
    printf("|                PUNTUACION FINAL                 |\n", puntuacion);
    printf("|                     %5d                       |\n", puntuacion);
    printf("+-------------------------------------------------+\n");

    // Liberar memoria en device
    cudaFree(origenTablero);
    cudaFree(destinoTablero);


    return 0;
}