pragma solidity ^0.5.16;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    FlightSuretyData flightSuretyData;
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    bool private operational = true;        // Blocks all state changes throughout the contract if false

    uint256 minimum_required = 4;

    uint256 minimum_fee_allowed = 10;

    uint256 insurance_max_amount = 1;

    struct Flight {
        address airlineAddress;
        //uint256 feePaid;
        bool completed;
        uint256 registeredInd;
        mapping(address => bool) alreadyVoted;
        uint256 totalVotes;
    }

    Flight[] public registrations;
    address[] public purposedAirlines;

    mapping(address => uint256) public registeredIndexAirline;
    mapping(address => bool) public voted;

    /********************************************************************************************/
    /*                                       EVENTS                                */
    /********************************************************************************************/

    event airlineRegistered(uint256 registeredInd, address airlineAddress);
    event airlineFunded(address airlineAddress, uint256 payment);
    event flightRegistered(bytes32 id);
    event clientPurchaseInsurance(address client, bytes32 flightId);
    event purposedRegistration(address airlineAddress, uint256 registeredInd, bool completed, uint256 totalVotes);
    event votedonRegistration(address airlineAddress, uint256 _registeredInd);
    event OperationalStatusChanged(bool mode);


    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */

    modifier requireIsOperational() {
         // Modify to call data contract's status
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "This caller is not the contract owner");
        _;
    }

    modifier requireRegisteredAirlines() {
        require(flightSuretyData.istheAirlineRegistered(msg.sender), "This caller is not a registered Airline");                                       //calling the registered airline from data contract
        _;
    }


    modifier requireFundedAirline() {
        require(flightSuretyData.isAirlineFunded(msg.sender), "This caller has not submitted a payment");                                       //calling if airline has paid from data contract
        _;
    }

    modifier indexLive(uint256 registeredInd) {
        require(registeredInd <= registrations.length, "This number does not exist");
        _;
    }

    modifier unperformed(uint256 registeredInd) {
        Flight storage registration = registrations[registeredInd];
        require(registration.completed == false, "This regristration has already been performed");
        _;
    }

    modifier noVotesExist(uint256 registeredInd) {
        Flight storage registration = registrations[registeredInd];
        require(!registration.alreadyVoted[msg.sender], "This regristation has already been voted for");
        _;
    }

    modifier RegistrationofFlight(bytes32 keyFlight) {
        require(!flightSuretyData.theregisteredFlight(keyFlight), 'This flight has not been registered');
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */

    constructor(address payable _dataContract) public {
        contractOwner = msg.sender;

        registrations.push(Flight({
            airlineAddress: msg.sender,
            completed: true,
            registeredInd: 0,
            totalVotes: 0
        }));


        flightSuretyData = FlightSuretyData(_dataContract);

    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public returns(bool) {
        return flightSuretyData.isOperational();  // Modify to call data contract's status
    }

    /**
    * @dev allows contract owner to kill the contract permanently
    *
    */

    function setOperatingStatus (bool mode) external requireContractOwner requireIsOperational{
        require(mode != operational, "You may not set the same state more than once");
        operational = mode;
        emit OperationalStatusChanged(mode);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev turn in airline registration, applicable only if more than 4 airlines registered
    *
    */

    function turninRegistration (address _airlines) external payable requireIsOperational {

        uint256 _registeredInd = registrations.length;

        registrations.push(Flight({
            airlineAddress: _airlines,
            completed: false,
            registeredInd: _registeredInd,
            totalVotes: 0
        }));

        purposedAirlines.push(_airlines);
        registeredIndexAirline[_airlines] = _registeredInd;

        bool conditionCompleted = false;
        uint256 voteAmounts = 0;

        emit purposedRegistration(_airlines, _registeredInd, conditionCompleted, voteAmounts);
    }


    function receiveRegisteredInd (address _airlines) external returns (uint256) {
        return registeredIndexAirline[_airlines];

    }

    function receivePurposedAirlines() external view requireIsOperational returns (address[] memory) {
        return purposedAirlines;
    }

    function receiveAppliedRegristration (uint256 _indexNum) external view requireIsOperational returns (address) {
        return registrations[_indexNum].airlineAddress;
    }

    /**
    * @dev receive airline vote, applicable only if more than 4 airlines registered
    *
    */

    function receiveVotes (uint256 _registeredInd) external returns (bool) {
        //Registration storage registration = registrations[_regIndex];
        bool condition =  registrations[_registeredInd].alreadyVoted[msg.sender];
        return (condition);
    }

    /**
    * @dev vote registration, applicable only if more than 4 airlines registered
    *
    */

    function registerVotes (uint _registeredInd) external requireRegisteredAirlines requireIsOperational indexLive(_registeredInd) unperformed(_registeredInd) noVotesExist(_registeredInd){

        registrations[_registeredInd].totalVotes += 1;
        registrations[_registeredInd].alreadyVoted[msg.sender] = true;

        emit votedonRegistration(msg.sender, _registeredInd);
    }


    /**
    * @dev apply registration, applicable only if more than 4 airlines registered
    *
    */

    function applyRegistration(uint256 _registeredInd) external requireIsOperational requireRegisteredAirlines indexLive(_registeredInd) unperformed(_registeredInd) {
        require(!flightSuretyData.istheAirlineRegistered(registrations[_registeredInd].airlineAddress), "This airline has already been regristered");

        uint256 theAirlines = flightSuretyData.amountofAirlines();
        uint256 votesNeeded = 3;

        address _airlines = registrations[_registeredInd].airlineAddress;

        if(theAirlines <= minimum_required) {

            registrations[_registeredInd].completed = true;

            flightSuretyData.inputAirlines(registrations[_registeredInd].airlineAddress, true, _registeredInd, 0);

            emit airlineRegistered(_registeredInd, _airlines);

        } else if(theAirlines > minimum_required) {

            require(registrations[_registeredInd].totalVotes >= votesNeeded, "This airline can not be registered");

            registrations[_registeredInd].completed = true;

            flightSuretyData.inputAirlines(registrations[_registeredInd].airlineAddress, true, _registeredInd, registrations[_registeredInd].totalVotes);


            emit airlineRegistered(_registeredInd, _airlines);
        } else {

        }

    }

   /**
    * @dev pay for airline
    *
    */

    function payAirline() external payable requireIsOperational requireRegisteredAirlines {
        require(msg.value >= minimum_fee_allowed, "The fee amount is too low");

        flightSuretyData.payMinFee(msg.sender, msg.value);
        emit airlineFunded(msg.sender, msg.value);
    }


    /**
    * @dev register a future flight
    *
    */

    function registertheFlight (string calldata flightName, uint256 timestamp) external requireIsOperational {
        bytes32 key = createFlightkey(msg.sender, flightName, timestamp);
        require(!flightSuretyData.theregisteredFlight(key), 'This flight has already been registered');

        bool status = true;

        flightSuretyData.registerFlight(key, msg.sender, status, flightName, timestamp, STATUS_CODE_UNKNOWN);

        emit flightRegistered(key);
    }

    /**
    * @dev create an id by hashing the 3 variables
    *
    */

    function createFlightkey (address airlineAddress, string memory flightName, uint256 timestamp) public requireIsOperational returns (bytes32) {
        return keccak256(abi.encodePacked(airlineAddress, flightName, timestamp));
    }



    /**
    * @dev process the flight status and give out the status on wether the flight is late or not
    *
    */

    function processFlightStatus (address airlineAddress, string memory flight, uint256 timestamp, uint8 statusCode) public requireIsOperational {
        bytes32 key = createFlightkey(airlineAddress, flight, timestamp);
        (, , , uint256 _status) = flightSuretyData.getFlightData(key);
        require(_status == 0, "This has been looked into");
        flightSuretyData.setFlightStatus(key, statusCode);

        if (statusCode == STATUS_CODE_LATE_AIRLINE){
            flightSuretyData.processFlightStatus(key,true);
        } else {
            flightSuretyData.processFlightStatus(key,false);
        }

    }


    /**
    * @dev for clients to buy insurance
    *
    */

    function buyInsurance (bytes32 flightId) internal requireIsOperational {
        require(msg.value <= insurance_max_amount, '1 eth < to purchase');
        flightSuretyData.fund(msg.sender, msg.value, flightId);

        emit clientPurchaseInsurance(msg.sender, flightId);
    }


    /**
    * @dev to allow clients to take out funds due to late flight
    *
    */

    function withdrawalFunds (bytes32 flightkey) public payable requireIsOperational {
        //(bool paid, uint256 amount, bytes32 flightId , bool eligiblepayout) = flightSuretyData.passengerInfo(msg.sender);
        flightSuretyData.payout(msg.sender, flightkey);

    }


    // Generate a request for oracles to fetch flight information

    function fetchFlightStatus (bytes32 flightkey) external {
        uint8 index = getRandomIndex(msg.sender);

        //(string memory flightName, address airline, uint256 timestamp) = flightSuretyData(flightKey);

        // Generate a unique key for storing the request
        (string memory flightName, uint256 timestamp, address airlineAddress, ) = flightSuretyData.getFlightData(flightkey);

        bytes32 key = keccak256(abi.encodePacked(index, airlineAddress, flightName, timestamp));

        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airlineAddress, flightName, timestamp);
    }


    function receiveUpdatedFlights() external view requireIsOperational returns(bytes32[] memory) {
        return flightSuretyData.receiveFlights();
    }



    function getFlightInformation(bytes32 flightKey) external view requireIsOperational returns (string memory flightName, uint256 flightTime, address airlineAddress, uint256 status) {
        return flightSuretyData.getFlightData(flightKey);
    }

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airlineAddress, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airlineAddress, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable {

        // Require registration fee

        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes() view external returns(uint8[3] memory) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");
        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)

    function submitOracleResponse(uint8 index, address airlineAddress, string calldata flight, uint256 timestamp, uint8 statusCode) external {

        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airlineAddress, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES

        // oracles respond with the *** same *** information

        emit OracleReport(airlineAddress, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airlineAddress, flight, timestamp, statusCode);

            // Handle flight status as appropriate

            processFlightStatus(airlineAddress, flight, timestamp, statusCode);
        }
    }


    function getFlightKey(address airlineAddress, string memory flight, uint256 timestamp) internal returns(bytes32) {
        return keccak256(abi.encodePacked(airlineAddress, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9

    function generateIndexes(address account) internal returns(uint8[3] memory) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9

    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation

        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}
