const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = function(deployer, network, accounts) {

    let firstAirline = accounts[0];
    let firstFlight = 'New Airline';
    deployer.deploy(FlightSuretyData, firstAirline, firstFlight)
        .then(() => {
            return FlightSuretyData.deployed();
        })
        .then((dataContractInstance) => {
            return deployer.deploy(FlightSuretyApp, FlightSuretyData.address)
                    .then(() => {
                        dataContractInstance.authorizeCaller(FlightSuretyApp.address);
                        let config = {
                            localhost: {
                                url: 'http://localhost:9545',
                                dataAddress: FlightSuretyData.address,
                                appAddress: FlightSuretyApp.address
                            }
                        }
                        fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                        fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                    });
        });
}