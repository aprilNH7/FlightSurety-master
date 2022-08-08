import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];

            let counter = 1;

            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    AirlineisRegistered(airline, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .AirlineisRegistered(airline)
            .call({from: self.owner}, callback);
    }

    AirlineisFunded(airline, callback) {
        let self = this;
        self.flightSuretyData.methods
            .AirlineisFunded(airline)
            .call({from: self.owner}, callback);
    }

    registerAirline(airline, fromAccount, flight, callback) {
       let self = this;
       console.log("register the airline: airline---"+airline+" from the Account: "+fromAccount +" flight: " + flight)
       self.flightSuretyApp.methods
           .registerAirline(airline, flight)
           .send({from: fromAccount, gas: 4000000, gasPrice: 100000000000}, callback);
   }

   fund(airline, callback) {
        let self = this;
        console.log("contract has been funded, airline: " + airline);
        self.flightSuretyApp.methods
            .fund()
            .send({from: airline, value: this.web3.utils.toWei("10", "ether"), gas: 4000000, gasPrice: 100000000000}, callback);
    }

    buy(passengerAccount, airline, flight, timestamp, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .buyInsurance(airline, flight, timestamp)
            .send({from: passengerAccount, value: this.web3.utils.toWei("1", "ether"), gas: 4000000, gasPrice: 100000000000}, callback);

    }

    registerFlight(airline, flight, timestamp, callback) {
        let self = this
        self.flightSuretyApp.methods
            .registerFlight(flight, timestamp)
            .send({from: airline, gas: 4000000, gasPrice: 100000000000}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    async accountBalance(account) {
         let balance = await this.web3.eth.getBalance(account);
         return await this.web3.utils.fromWei(balance);
    }

    submitOracleResponse(index, airline, flight, timestamp, status_code) {
        let self = this;
        self.flightSuretyApp.methods
            .submitOracleResponse(index, airline, flight, timestamp, status_code)
            .send({from: self.owner });
    }

    pay(passengerAccount, airline, flight, timestamp, callback) {
        let self = this;
        self.flightSuretyApp.methods
            .withdrawValue()
            .send({from: passengerAccount}, callback);
        }

}
