import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network) {

        this.config = Config[network]; //this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.owner = null;
        this.flights = [];
        this.airlines = [];
        this.clients = [];
        this.gasLimit = 40000000;
    }


    async initWeb3 (logCallback) {
        if (window.ethereum) {
            this.web3 = new Web3(window.ethereum);
            try {
                // Get contract permission
                await window.ethereum.enable();
            } catch (error) {
                // Can not get contract permission
                console.error("You are not allowed access")
            }
        }
        // The Dapp Browsers
        else if (window.web3) {
            this.web3 = new Web3(window.web3.currentProvider);
        }
        // Fall back line linked to Ganache
        else {
            this.web3 = new Web3(new Web3.providers.WebsocketProvider('http://localhost:9545'));
        }

        const accounts = await this.web3.eth.getAccounts();
        this.account = accounts[0];

        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, this.config.appAddress, this.config.dataAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, this.config.dataAddress);
        this.flightSuretyApp.events.allEvents({fromBlock: 'latest', toBlock: 'latest'}, logCallback);
        this.flightSuretyData.events.allEvents({fromBlock: 'latest', toBlock: 'latest'}, logCallback);
    }

    async registerFlight( flightName, flightTime) {
        await this.flightSuretyApp.methods.registertheFlight(flightName, flightTime).send({from: this.account, gas: this.gasLimit});
    }

    async inputAirline(_address) {
        let self = this;
        try {
           await self.flightSuretyApp.methods.turninRegistration(_address).send({from: self.account, gas: self.gasLimit});
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    async registerVotes(_address) {
        let self = this;
        try {
            let index = await this.flightSuretyApp.methods.receiveRegisteredInd(_address).call();
           await self.flightSuretyApp.methods.registerVotes(index).send({from: self.account, gas: self.gasLimit});
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    async applyRegistration(_address) {
        let self = this;
        try {
            let index = await this.flightSuretyApp.methods.receiveRegisteredInd(_address).call();
           await self.flightSuretyApp.methods.applyRegistration(index).send({from: self.account, gas: self.gasLimit});
        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }

    async receiveUpdatedFlights() {
        return await this.flightSuretyApp.methods.receiveUpdatedFlights().call();
    }

    async getFlightInformation(key) {
        return await this.flightSuretyApp.methods.getFlightInformation(key).call();
    }

    async payAirline() {
        await this.flightSuretyApp.methods.payAirline().send({from: this.account, value: 10000000000000000000});
    }

    async setOperationalStatus(enabled) {
        await this.flightSuretyData.methods.setOperatingStatus(enabled).send({from: this.account});
    }

    async setOperationalStatusFalseApp(enabled) {
        await this.flightSuretyApp.methods.setOperatingStatus(enabled).send({from: this.account});
    }

    async isOperational() {
        return await this.flightSuretyData.methods.isOperational().call();
    }

    async amountofAirlines() {
        return await this.flightSuretyAdata.methods.amountofAirlines().call();
    }

    async getNumberOfFundedAirlines() {
        return await this.flightSuretyApp.methods.getNumberOfFundedAirlines().call();
    }

    async getContractBalance() {
        const contractBalance =  await this.flightSuretydata.methods.receiveRemainder().call();
        return `${this.web3.utils.fromWei(contractBalance, 'finney')} finney`;
    }

    async receivePurposedAirlines() {
        return await this.flightSuretydata.methods.receivePurposedAirlines().call();
    }

    async receiveAppliedRegristration(numberIndex) {
        return await this.flightSuretyApp.methods.receiveAppliedRegristration(indexNum).call();
    }

    async purchaseInsurance(flightKey) {
        await this.flightSuretyApp.methods.purchaseInsurance(flightKey).send({from: this.account, value: 1000000000000000000});
    }

    async payoutFunds() {
        await this.flightSuretyApp.methods.withdrawalFunds().send({from: this.account});
    }

    async fetchFlightStatus(flightKey) {
        await this.flightSuretyApp.methods.fetchFlightStatus(flightKey).send({from: this.account})
    }

}
