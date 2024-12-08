# Proyecto: Gestión de Skins en Videojuegos

Este proyecto implementa un sistema para la gestión de skins en videojuegos mediante contratos inteligentes en Solidity. Permite realizar operaciones como venta, alquiler y subastas de skins utilizando Ether como moneda.

## Autores
- **Axel Valladares Pazó**   tiempo dedicado: 30 horas aproximadamente
- **Pedro Blanco Casal**     tiempo dedicado: 30 horas aproximadamente

---

## Tabla de Contenidos
1. [Explicación del Código](#explicación-del-código)
2. [Cómo Montarlo](#cómo-montarlo)
3. [Lanzamiento del Código](#lanzamiento-del-código)

   
---

## Explicación del Código

### Smart Contract: Tienda

El contrato inteligente está desarrollado con la finalidad de administrar skins de un videojuegos de forma que el usuario que despliegue el contrato sea el único que cree estas skins y los otros usuarios, hagan de clientes, pudiendo comprarlas, alquilarlas o pujar en una subasta por ellas.

En el código se importa el módulo Ownable de OpenZeppelin, que proporciona una gestión de permisos básicos para un administrador (propietario del contrato). El contrato Tienda hereda de Ownable, permitiendo una administración centralizada para ciertas funciones que veremos posteriormente.

En este sistema, cada skin se define mediante una estructura que contiene información como su identificador, nombre, ubicación del archivo, propietario, precios de compra y alquiler, estado de disponibilidad y datos relacionados con subastas o alquileres. Los skins se almacenan en un mapeo que asocia cada identificador único con su correspondiente estructura. Además, se lleva un conteo total de skins registrados mediante una variable de estado **contadorSkins**. La dirección del administrador del contrato, **admin**, se almacena para gestionar permisos en funciones críticas.

Un modificador garantiza que solo el administrador pueda ejecutar ciertas funciones sensibles, como CrearSkins, MontarSubasta y recogerSubasta. El contrato tiene un constructor que inicializa los valores clave, como el contador de skins y el administrador, estableciendo al creador del contrato como propietario inicial.

También hay un sistema para asociar archivos a direcciones de usuarios, para almacenar las imagenes de las skins en una red IPFS cuyo propietario es el administrador. 

Se pueden crear las skins, comprarlas, alquilarlas o montar una subasta por ellas.

Cuando deseamos montar la subasta el administrador debe ejecutar **montarSubasta** enviando como parámetro al dirección de la skin creada y el tiempo mínimo, en minutos, que la subasta estará abierta. Tras ello, los clientes podrán pujar, esto devolverá a los anteriores pujadores el dinero que ofrecieron por la skin, através de msg.value, que debe ser obviamente a cada puja un valor mayor. Cuando el tiempo haya transcurrido ya no se podrá pujar más.

Cuando el administrador desee acabar la subasta tras el tiempo transcurrido, ejecutará **recogerSubasta** enviando como parámetro al dirección de la skin creada. Esto al administrador los fondos que haya gastado el último pujador, desde el balance del propio contrato.

Es importante tener en cuenta que por simplificar la complejidad del contrato, el archivo almacenado en la IPFS siempre se almacenará ahí y que cuando un usuario compre la skin correspondiente a dicho archivo, se cambiará de propietario pero la imagen permanecerá en la IPFS.


### Aplicación Web con REACT

La aplicación permite a los usuarios interactuar con un contrato inteligente que maneja la compra, alquiler y subasta de skins. Se conecta a la blockchain utilizando la biblioteca ethers.js y permite la interacción con archivos almacenados en IPFS mediante kubo-rpc-client.

Se implementan múltiples estados para gestionar información como conexión del usuario, lista de skins, subastas, saldo en ETH y detalles de administración. La aplicación detecta automáticamente si el usuario es administrador, lo que habilita funciones específicas como la creación de skins o el montaje de subastas.

El flujo incluye:

Conexión a una wallet Ethereum: Mediante window.ethereum, los usuarios pueden habilitar su cuenta para interactuar con el contrato.

Carga de archivos a IPFS: Los usuarios pueden cargar archivos y vincularlos con skins mediante hashes CID de IPFS.

Creación de skins: Solo el administrador puede crear nuevos skins con un nombre, precios de compra y alquiler, y un archivo IPFS.

Compra de skins: Los usuarios pueden comprar skins disponibles por ETH, con el precio convertido a Wei para la transacción.

Alquiler de skins: Los usuarios pueden alquilar skins disponibles por ETH, con el precio convertido a Wei para la transacción y multiplicado por la cantidad de días que se desee alquilar.(en este caso, se usaron minutos para realizar todas las pruebas cómodamente)

Subastas: Los skins pueden subastarse, y los usuarios pueden pujar aumentando el precio actual. El administrador puede finalizar las subastas.

Interfaz visual: Presenta secciones como:
1. Skins disponibles para compra.
2. Subastas activas.
3. Skins propias del usuario.
4. Skins alquiladas.
5. Panel de administración con opciones avanzadas.

El código también contiene validaciones para garantizar que los campos estén completos antes de ejecutar transacciones y que los datos sean válidos
---

## Lanzamiento del Código

Para desplegar y ejecutar la IPFS y la aplicación web:  
1. Asegúrate de tener instalado **Node.js** y **npm** (Node Package Manager).  
2. Debemos tener también el docker de ipfs/kubo desplegado.
3. Ejecutamos dentro de la carpeta **mi-bazar-dapp** el comando:
   ```bash
   npm install
   
   # y tras ello:
   
   npm start
   
4. Veremos finalmente desplegado el servicio en http://localhost:3000/   


