// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MiBazar is Ownable {
    struct Skin {
        uint256 id;
        string name;
        string file;
        address propietario;
        uint256 precio_compra;
        uint256 precio_alquiler;
        uint256 tiempo_limite;
        bool en_subasta;
        bool disponible_para_compra;
        bool disponible_para_alquiler;
        address usuario_en_alquiler;
    }

    mapping(uint256 => Skin) public almacenSkins;
    uint256 public contadorSkins;
    address public admin;

    AggregatorV3Interface internal priceFeed;

    modifier soloPropietario {
        require(msg.sender == admin, "No eres el propietario");
        _;
    }

    constructor() Ownable(msg.sender) {
        contadorSkins = 0;
        admin = msg.sender;

        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getLatestPrice() public view returns (int256) {
        (
            ,
            int256 price,
            ,
            ,
        ) = priceFeed.latestRoundData();
        return price; // Devuelve el precio con 8 decimales
    }

    mapping (address => string) public userFiles;
    

    function _crearSkin(string memory _name, string memory _file, uint256 _precio_compra, uint256 _precio_alquiler) external soloPropietario {
        contadorSkins++;
        almacenSkins[contadorSkins] = Skin(
            contadorSkins,
            _name,
            userFiles[msg.sender] = _file,
            admin,
            _precio_compra,
            _precio_alquiler,
            0,
            true,
            true,
            true,
            address(0)
        );
    }


    function comprarSkin(uint256 _id) public payable {
        require(_id <= contadorSkins, "El producto no existe");
        require(almacenSkins[_id].disponible_para_compra, "Skin no disponible para compra");
        require(msg.value >= almacenSkins[_id].precio_compra, "No enviaste suficiente Ether");
        
        // Transferir ETH al propietario (admin)
        payable(admin).transfer(msg.value);

        //Se actualizan valores de la skin
        almacenSkins[_id].propietario = msg.sender;
        almacenSkins[_id].disponible_para_compra = false;
        almacenSkins[_id].disponible_para_alquiler = false;
        almacenSkins[_id].en_subasta=false;
        almacenSkins[_id].tiempo_limite = 0;
    }


    function alquilarSkin(uint256 _id, uint256 _diasAlquiler) public payable {
        require(_id <= contadorSkins, "El producto no existe");
        require(_diasAlquiler > 0, "La duracion del alquiler debe ser mayor a 0");

        //Skin storage skin = almacenSkins[_id];
        require(almacenSkins[_id].disponible_para_compra, "Skin ya vendida o en alquiler");
        require(almacenSkins[_id].disponible_para_alquiler, "Skin alquilandose en este momento");

        uint costoAlquiler = almacenSkins[_id].precio_alquiler * _diasAlquiler;
        require(msg.value >= costoAlquiler, "No se ha enviado suficiente ETH para el alquiler");

        // Transferir ETH al propietario (admin)
        payable(admin).transfer(msg.value);

        //Se actualizan valores de la skin
        almacenSkins[_id].disponible_para_compra=false;
        almacenSkins[_id].disponible_para_alquiler=false;
        almacenSkins[_id].en_subasta=false;
        almacenSkins[_id].usuario_en_alquiler = msg.sender;
        almacenSkins[_id].tiempo_limite = block.timestamp + (_diasAlquiler * 1 minutes); //Esta en minutes para hacer pruebas, pero debe estar en days
    }

    function devolverSkin(uint256 _id) public payable{
        require(_id <= contadorSkins, "El producto no existe");
        require(almacenSkins[_id].usuario_en_alquiler == msg.sender, "No tienes esta skin alquilada");
        require(almacenSkins[_id].tiempo_limite!=0, "Esta Skin no se esta alquilando");
        
        uint256 aux_tiempo_limite = almacenSkins[_id].tiempo_limite;

        //Se actualizan valores de la skin
        almacenSkins[_id].disponible_para_alquiler=true;
        almacenSkins[_id].disponible_para_compra=true;
        almacenSkins[_id].en_subasta=true;
        almacenSkins[_id].usuario_en_alquiler = address(0);
        almacenSkins[_id].tiempo_limite = 0;

        //Cobrar al usuario si se paso de tiempo
        if(block.timestamp>aux_tiempo_limite){
            payable(admin).transfer(msg.value);
        }
    }

    function pujar(uint256 _id) public payable {
        require(_id <= contadorSkins, "El producto no existe");
        require(almacenSkins[_id].en_subasta, "La skin no esta en subasta");
        require(!almacenSkins[_id].disponible_para_compra, "La subasta no esta montada");
        require(block.timestamp <= almacenSkins[_id].tiempo_limite, "La subasta ya termino");
        require(msg.value > almacenSkins[_id].precio_compra, "La puja debe ser mayor al precio actual");

        if (almacenSkins[_id].propietario != admin) {// Transferir ETH al bazar
            payable(almacenSkins[_id].propietario).transfer(almacenSkins[_id].precio_compra);
        }
        //Se actualizan valores de la skin
        almacenSkins[_id].precio_compra = msg.value;
        almacenSkins[_id].propietario = msg.sender;
    }


    function _recogerSubastas() external soloPropietario {
        for(uint256 id=0; id<=contadorSkins; id++){
            if(id <= contadorSkins){
                if(almacenSkins[id].en_subasta && !almacenSkins[id].disponible_para_compra && !almacenSkins[id].disponible_para_alquiler){
                    if(block.timestamp > almacenSkins[id].tiempo_limite){
                        // Transferir ETH al propietario (admin)
                        payable(admin).transfer(almacenSkins[id].precio_compra);
                        //Se actualizan valores de la skin
                        almacenSkins[id].en_subasta = false;      
                        almacenSkins[id].tiempo_limite = 0;
                    }
                }
            } 
        }
    }

    function _montarSubasta(uint256 _id, uint256 tiempo) external soloPropietario {
        require(_id <= contadorSkins, "El producto no existe");
        require(almacenSkins[_id].en_subasta, "La skin no esta para subasta");
        
        //Se actualizan valores de la skin
        almacenSkins[_id].disponible_para_compra = false;
        almacenSkins[_id].disponible_para_alquiler=false;
        almacenSkins[_id].tiempo_limite = block.timestamp + (tiempo * 1 minutes);
    }
}
