
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {

    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0x0c6a360C39389d86C2a499374013BBf680bf5C44",
        "0x8633b41c3beDa3231DE63cb12f3f2283a6674EAA",
        "0xA673e20fdbb8215Bb58d19df3731ABCb6c86eB0A",
        "0xa364e6140C2d447770F914c349BF47B3faB748C5",
        "0x4f15B7C4baF5fB6686e134eAcaecA3125396324D",
        "0xAa62dF1b7Fa8D894CE282C80B9B176821811BD28",
        "0xb0ED14de3D66750Ad08a9702e3263ff67DF76cb8",
        "0xCE305F1017b9BbBe03e00ECa345D02fA4F2FA2B3",
        "0xB1BFa9AdA60740e551df5f6a7D7553779eE4666c"
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];

    let flightSuretyData = await FlightSuretyData.new();
    let flightSuretyApp = await FlightSuretyApp.new();


    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};
