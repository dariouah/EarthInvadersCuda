# EarthInvadersCuda

Bienvenido al repositorio de EarthInvaders, una reinvención del clásico juego de arcade implementado en CUDA para aprovechar la potencia de cálculo de las tarjetas gráficas NVIDIA. Este proyecto lleva la programación en la GPU a un nuevo nivel, ofreciencio una ejecucion de alto rendimiento, aprovechando el cómputo paralelo en la GPU.

## Requisitos Previos y Configuración

Para ejecutar EarthInvaders, es **esencial** tener una tarjeta gráfica NVIDIA compatible, ya que el juego está desarrollado utilizando CUDA, una plataforma de computación paralela y modelo de programación inventada por NVIDIA.

Además, asegúrate de tener instalados los siguientes componentes:
- Los últimos drivers de NVIDIA para tu tarjeta gráfica.
- CUDA Toolkit, compatible con la versión de los drivers instalados y tu tarjeta gráfica.
- Visual Studio, necesario para compilar el proyecto.

Para facilitar el proceso de instalación y configuración, se adjunta un [archivo de instrucciones](/instalacion-cuda.pdf) con instrucciones detalladas sobre cómo instalar y configurar los componentes necesarios, incluyendo la instalación de Visual Studio y CUDA Toolkit, y cómo preparar tu sistema para ejecutar EarthInvaders. Es crucial seguir estas instrucciones para asegurar que el entorno de desarrollo esté correctamente preparado.

## Compilación y Ejecución

1. Abre el proyecto en Visual Studio.
2. Asegúrate de que el Toolkit de CUDA esté correctamente configurado en las propiedades del proyecto.
3. Compila el proyecto.
4. Ejecuta el binario generado para comenzar a jugar EarthInvaders.
   
## Cómo Usar

Una vez que hayas compilado y ejecutado **EarthInvaders**, el juego te pedirá que introduzcas algunos parámetros iniciales para configurar tu experiencia de juego:

1. **Tamaño del Tablero**: Deberás introducir el tamaño del tablero en el que deseas jugar. Esto determinará el espacio de juego.

2. **Modo de Juego**: Indica si prefieres jugar en modo manual (`m`) o automático (`a`):
   - **Manual (`m`)**: Tendrás control total sobre el movimiento del jugador en el juego.
   - **Automático (`a`)**: El juego gestionará los movimientos por ti.

El juego comienza con **5 vidas**. Tu objetivo es evitar que los invasores destruyan tu base y acabar con ellos antes de que sea demasiado tarde.

### Controles

Durante el juego, usarás los siguientes controles para mover al jugador y defender la tierra:
- Presiona `'a'` para mover al jugador hacia la izquierda.
- Presiona `'d'` para mover al jugador hacia la derecha.

Cada iteración del juego te permite tomar una acción, así que elige sabiamente para maximizar tu eficacia en la defensa contra los invasores.

Recuerda, la supervivencia de la Tierra está en tus manos. ¡Buena suerte!

## Video Tutorial de Uso

Para complementar las instrucciones provistas en la sección "Cómo Usar", consulta el [video tutorial de uso](/ejemplo-como-usar.mp4). Se ve como interactua con el juego siguiendo las opciones de configuración inicial y los controles de movimiento.

Este video es especialmente útil si prefieres una guía visual que te lleve a través del proceso paso a paso, asegurando que puedas seguir las instrucciones y manejar el juego con éxito desde el comienzo.

Esperamos que este recurso te sea de gran ayuda y enriquezca tu experiencia al jugar **Earth Invaders**.

## Contribuir

Si estás interesado en contribuir a EarthInvaders, ya sea añadiendo nuevas características, optimizando el rendimiento del juego, o corrigiendo bugs, te invitamos a hacer fork del repositorio y enviar tus pull requests.

## Licencia

Este proyecto se comparte de manera libre y abierta. Se permite el uso, distribución y modificación sin restricciones. Sin embargo, se agradece el crédito al autor original en caso de uso público.
