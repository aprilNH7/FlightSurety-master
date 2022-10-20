pragma solidity ^0.5.16;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    uint256 private airlineBalance = 0 ether;                             // balance for funds from airlines registration
    uint256 private insuranceBalance = 0 ether;                           // balance for insurance
    mapping(address => bool) private authorizedCallers;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */

    struct Airline {
        address airlineAddress;
        bool isRegistered;
        uint256 feeSettled;
        uint256 registeredInd;
        bool isFunded;
        //mapping(address => bool) isVoted;
        uint totalVotes;
    }

    mapping(address => Airline) public theregisteredAirlines;

    //Flight struct

    struct Flight {
        string flightName;
        bool isRegistered;
        uint256 flightTime;
        uint256 registeredInd;
        address airlineAddress;
        uint256 statusCode;
        uint256 newTimestamp;
        address[] protectedClient;
        mapping(address => uint256) protectedClientAddress;
    }

    struct Client {
        bool isPaid;
        uint256 paidValue;
        bytes32 flightId;
        bool payout;
        uint256 insurance;
    }

    uint256 indicator;
    uint256[] private airlines;
    mapping(address => bool) private _airlinePaid;

    //string mapping flight

    mapping(bytes32 => Flight) private MappingofFlight;

    //mapping of client

    mapping(address => Client) private clients;

    bytes32[] private flightsArray;


    //EVENT

    event AirlineInfo();
    event PaidAmount(address airlineAddress, uint256 payment, uint256 balance);
    event ContractAuthorized(address _contractId);
    event OperationalStatusChanged(bool _state);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */

    constructor(address airlineAddress) public payable {
        contractOwner = msg.sender;
        _theregisteredAirlines(airlineAddress, true, 0, 0);
        //_payFeeAirline(airline, msg.value);
        indicator = 0;
    }


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */

    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */

    modifier isAirlineRegistered() {
        require(theregisteredAirlines[msg.sender].isRegistered == true, "Caller is not contract owner");
        _;
    }

    modifier isClientPaid() {
        require(clients[msg.sender].isPaid == false, "Caller has paid");
        _;
    }

    modifier isFlightregistered(bytes32 flight) {
        require(MappingofFlight[flight].isRegistered == true, "flight has not been registered");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function authorizeCaller(address contractAddress) external requireContractOwner{
        require(authorizedCallers[contractAddress] == false, "Address has already be registered");
        authorizedCallers[contractAddress] = true;
        emit ContractAuthorized(contractAddress);
    }

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */

    function isOperational() public view returns(bool) {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */

    function setOperatingStatus (bool mode) external requireContractOwner {
        require(mode != operational, "Can't set same state more than once");
        operational = mode;
        emit OperationalStatusChanged(mode);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */

    //requireIsOperational isAirlineRegistered

    function inputAirlines(address airlineAddress, bool isRegistered, uint256 registeredInd, uint256 totalVotes) external requireIsOperational {
        _theregisteredAirlines(airlineAddress, isRegistered, registeredInd, totalVotes);
    }

    /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */

    function _theregisteredAirlines(address _airlines, bool _isregistered, uint256 _registeredInd, uint256 _totalVotes) private requireIsOperational {

        airlines.push(indicator);
        indicator = indicator + 1;

        theregisteredAirlines[_airlines].airlineAddress = _airlines;
        theregisteredAirlines[_airlines].isRegistered = _isregistered;
        theregisteredAirlines[_airlines].feeSettled = 0;
        theregisteredAirlines[_airlines].registeredInd = _registeredInd;
        theregisteredAirlines[_airlines].isFunded = false;
        theregisteredAirlines[_airlines].totalVotes = _totalVotes;

    }

    /**
    * @dev check if airline is registered
    *      Can only be called from FlightSuretyApp contract
    *
    */

    function istheAirlineRegistered(address isAirline) external view requireIsOperational returns(bool) {
        return theregisteredAirlines[isAirline].isRegistered;
    }

    /**
    * @dev airline is paid by the airline address
    *      Can only be called from FlightSuretyApp contract
    *
    */

    //requireIsOperational isAirlineRegistered

    function payMinFee(address airlineAddress, uint256 fee) external payable requireIsOperational {
        _payMinFee(airlineAddress, fee);
    }

    /**
    * @dev airline is paid by the airline address
    *      Can only be called from FlightSuretyApp contract
    *
    */

    function _payMinFee (address _airlines, uint256 _fee) public payable requireIsOperational {
        theregisteredAirlines[_airlines].isFunded = true;
        theregisteredAirlines[_airlines].feeSettled = _fee;

        //contributions[msg.sender] += msg.value;
        airlineBalance = airlineBalance.add(_fee);


        emit PaidAmount(msg.sender, msg.value, airlineBalance);
    }

    /**
    * @dev getting remainder of funds held in this address
    *
    */

    function receiveRemainder() public view requireIsOperational  returns (uint256) {
        return address(this).balance;
    }

    /**
    * @dev check if the airline is funded
    *
    *
    */

    function isAirlineFunded (address _airlines) public requireIsOperational returns (bool) {
        return theregisteredAirlines[_airlines].isFunded;
    }

    /**
    * @dev check the amount of airlines registered
    *
    *
    */

    function amountofAirlines () public requireIsOperational returns (uint256) {
        return airlines.length;
    }


    /**
    * @dev add a flight
    *
    */

    function registerFlight(bytes32 key, address airlineAddress, bool status, string calldata flightName, uint256 timestamp, uint8 statusCode) external requireIsOperational {
        _registerFlight(key, airlineAddress, status, flightName, timestamp, statusCode);
    }

    /**
    * @dev add a flight
    *
    */

    function _registerFlight(bytes32 _key, address _airlines, bool _status, string memory _flightName, uint256 _timestamp, uint8 _statusCode) private {

        MappingofFlight[_key].flightName = _flightName;
        MappingofFlight[_key].flightTime = _timestamp;
        MappingofFlight[_key].airlineAddress = _airlines;
        MappingofFlight[_key].statusCode = _statusCode;
        MappingofFlight[_key].isRegistered = _status;
        flightsArray.push(_key);
    }

    /**
    * @dev receive the flight registration status
    *
    */

    function theregisteredFlight (bytes32 keyFlight) external requireIsOperational returns (bool status) {
        return (MappingofFlight[keyFlight].isRegistered);
    }

    function receiveFlights() external view requireIsOperational returns (bytes32[] memory ) {
        return flightsArray;
    }

    /**
    * @dev fetching the flight data
    *
    */

    function fetchFlightData (bytes32 key) external view requireIsOperational returns (string memory, uint256, address, uint256) {
        require(MappingofFlight[key].airlineAddress != address(0));

        return (MappingofFlight[key].flightName, MappingofFlight[key].flightTime, MappingofFlight[key].airlineAddress, MappingofFlight[key].statusCode);
    }

    /**
    * @dev set flight the status
    *
    */

    function setFlightStatus (bytes32 key, uint8 status) external requireIsOperational {
        require(status != MappingofFlight[key].statusCode, "Status code already set");
        MappingofFlight[key].statusCode = status;
    }

    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts
    *
    *
    */

    function fund (address payable clientAddress, uint pay, bytes32 flightId) public requireIsOperational isClientPaid isFlightregistered(flightId) returns (bool success) {

        clients[clientAddress].isPaid = true;
        clients[clientAddress].paidValue = pay;
        clients[clientAddress].flightId = flightId;
        clients[clientAddress].payout = false;
        MappingofFlight[flightId].protectedClient.push(clientAddress);
        MappingofFlight[flightId].protectedClientAddress[clientAddress] = pay;
        clients[clientAddress].insurance = pay.div(2) + pay;

        insuranceBalance = insuranceBalance.add(clients[clientAddress].insurance);

        emit PaidAmount(msg.sender, pay, address(this).balance);

        return true;

    }

    function clientInfo (address _clientAddress) public view requireIsOperational returns (bool paid, uint256 payment, bytes32 flightId, bool payout) {
        paid = clients[_clientAddress].isPaid;
        payment = clients[_clientAddress].paidValue;
        flightId = clients[_clientAddress].flightId;
        payout = clients[_clientAddress].payout;

        return (paid, payment, flightId, payout);
    }

    /**
     *  @dev payout funds to clients
     *
    */

    function payout (address payable clientAddress, bytes32 flightkey) external payable requireIsOperational {
        require(clients[clientAddress].payout, "not eligible for payout");

        //Passenger storage passenger = passengers[passengerAddress];

        //passenger.PaidAmount = 0;
        clients[clientAddress].flightId = "";
        MappingofFlight[flightkey].protectedClientAddress[clientAddress] = 0;
        uint256 pay = clients[clientAddress].insurance;
        insuranceBalance = insuranceBalance.sub(pay);

        clientAddress.transfer(pay);

    }

     /**
     *  @dev processing the flight
     *
    */

    function processFlightStatus (bytes32 flightkey, bool isLate) external requireIsOperational {
        uint256 client;
        //uint256 payAmount;

        if (isLate) {
            for (client = 0; client < MappingofFlight[flightkey].protectedClient.length; client++) {
                if(clients[MappingofFlight[flightkey].protectedClient[client]].isPaid) {

                    //payAmount = passengers[flightsMapping[flightkey].insuredPassengers[passenger]].paidAmount;

                    clients[MappingofFlight[flightkey].protectedClient[client]].payout = true;

                    //passengers[flightsMapping[flightkey].insuredPassengers[passenger]].paidAmount= 0;

                    //passengers[flightsMapping[flightkey].insuredPassengers[passenger]].insuranceAmount = payout*1.5;

                    //insuranceFunds = insuranceFunds.sub(insuranceAmount*1.5);
                    MappingofFlight[flightkey].protectedClient.length = 0;
                }
            }
        } else{

            //need to understasd what to do if it is not late

        }
    }


    function getFlightData (bytes32 key) external view requireIsOperational returns(string memory, uint256, address, uint256) {
         require(MappingofFlight[key].airlineAddress != address(0));
        return (MappingofFlight[key].flightName, MappingofFlight[key].flightTime, MappingofFlight[key].airlineAddress, MappingofFlight[key].statusCode);
    }

    /**
    * @dev fallback function for funding contract
    *
    */

    function() external payable {

    }



}
