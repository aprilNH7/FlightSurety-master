pragma solidity ^ 0.5.16;

// import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint8;
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedCallers;
    mapping(address => Airline) private airlines;

    struct Airline {
        address airline;
        string name;
        bool isRegistered;
        bool isPaid;
        uint256 fund;
    }

    uint256 internal countAirlines = 0;

    struct Insurance {
        address payable customer;
        uint256 value;
        address airline;
        string flight;
        uint256 timeStamp;
    }

    mapping(bytes32 => Insurance[]) private protection;
    mapping(bytes32 => bool) private insuranceReceived;
    mapping(address => uint256) private credittheCustomer;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */

    constructor(address airline, string memory flight) public {
        contractOwner = msg.sender;
        includeAirline(airline, flight);
    }

    /********************************************************************************************/
    /*                                       Events                                             */
    /********************************************************************************************/

    event AirlineisRegistered(address indexed airline, string flight);

    event AirlineisFunded(address indexed airline, uint256 value);

    event InsurancePurchased(address indexed customer, uint256 value, address airline, string flight, uint256 timeStamp);

    event InsuranceFundsAccessible(address indexed account, string indexed flight);

    event InsuranceFunded(address indexed customer, uint256 value);

    event InsurancePaid(address indexed customer, uint256 value);

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

    modifier requireIsCallerAuthorized() {
        require(authorizedCallers[msg.sender], "Caller is not authorized");
        _;
    }

    modifier requireAirlineisRegistered() {
        require(airlines[msg.sender].isRegistered, "Airline is not registered");
        _;
    }

    modifier requireAirlineisFunded() {
        require(airlines[msg.sender].isPaid, "Airline is not funded");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

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

    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function authorizeCaller(address contractAddress) external requireContractOwner {
        authorizedCallers[contractAddress] = true;
    }

    function deauthorizeCaller(address contractAddress) external requireContractOwner {
        authorizedCallers[contractAddress] = false;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */

    function registerAirline(address airline, string calldata flight) external requireIsCallerAuthorized{
       includeAirline(airline, flight);
   }

    function includeAirline(address airline, string memory flight) private {
        countAirlines = countAirlines.add(1);
        airlines[airline] = Airline(airline, flight, true, false, 0);
        emit AirlineisRegistered(airline, flight);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */

    function buy(address payable customer, address airline, string calldata flight, uint256 timeStamp) external payable {
        bytes32 flightKey = getFlightKey(airline, flight, timeStamp);
        airlines[airline].fund = airlines[airline].fund.add(msg.value);
        protection[flightKey].push(Insurance(customer, msg.value, airline, flight, timeStamp));
        emit InsurancePurchased(customer, msg.value, airline, flight, timeStamp);
    }

    /**
     *  @dev Credits payouts to customers
    */

    function creditCustomer(address airline, string calldata flight, uint256 timeStamp) external requireIsCallerAuthorized {
        bytes32 flightKey = getFlightKey(airline, flight, timeStamp);
        require(!insuranceReceived[flightKey], "Insurance has already been received");
        for (uint i = 0; i < protection[flightKey].length; i++) {
            address customer = protection[flightKey][i].customer;
            uint256 valueCredited = protection[flightKey][i].value.mul(3).div(2);
            credittheCustomer[customer] = credittheCustomer[customer].add(valueCredited);
            airlines[airline].fund = airlines[airline].fund.sub(valueCredited);
            emit InsuranceFunded(customer, valueCredited);
        }
        insuranceReceived[flightKey] = true;
        emit InsuranceFundsAccessible(airline, flight);
    }

    /**
     *  @dev Transfers eligible payout funds to customer
     *
    */

    function pay(address payable customer) external requireIsCallerAuthorized {
        uint256 value = credittheCustomer[customer];
        delete(credittheCustomer[customer]);
        customer.transfer(value);
        emit InsurancePaid(customer, value);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */

    function fund(address airline) external payable requireIsCallerAuthorized {
        includeFund(airline, msg.value);
        airlines[airline].isPaid = true;
        emit AirlineisFunded(airline, msg.value);
    }

    function includeFund(address airline, uint256 payValue) private {
        airlines[airline].fund = airlines[airline].fund.add(payValue);
    }

    function AirlineisPaid(address airline) external view requireIsCallerAuthorized returns(bool) {
        return airlines[airline].isPaid == true;
    }

    function receivePay(address airline) external view requireIsCallerAuthorized returns(uint256) {
        return airlines[airline].fund;
    }

    function receiveAirlineCount() external view returns(uint256) {
        return countAirlines;
    }

    function isAirlineRegistered(address airline) external view returns(bool) {
        return airlines[airline].isRegistered == true;
    }


    function receiveAmountPaidByCustomer(address payable customer, address airline, string calldata flight, uint256 timeStamp) external view returns(uint256 valuePaid) {
        valuePaid = 0;
        bytes32 flightKey = getFlightKey(airline, flight, timeStamp);
        for (uint i = 0; i < protection[flightKey].length; i++) {
            if (protection[flightKey][i].customer == customer) {
                valuePaid = protection[flightKey][i].value;
                break;
            }
        }
    }

    function receiveCustomerFunded(address payable customer) external view returns(uint256 value) {
        return credittheCustomer[customer];
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */

    function() external payable requireAirlineisRegistered {
        includeFund(msg.sender, msg.value);
        airlines[msg.sender].isPaid = true;
        emit AirlineisFunded(msg.sender, msg.value);
    }
}
