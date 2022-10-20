
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/


  it(`Has correct initial isOperational() value`, async function () {

    // Get operating status

    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "initial operating status value is not correct");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for a non-Contract Owner account

      let accessDenied = false;
      try {
          await config.flightSuretyData.setOperatingStatus(false, {from: config.testAddresses[2]});
      }
      catch(error) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "access is not contained to only Contract Owner");

  });


  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account

      let accessDenied = false;
      try
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "access is not contained to only Contract Owner");

  });


  it(`Can block access to functions using requireIsOperational when operating status is false`, async function () {

    let reverted = false;
    try {
        await config.flightSuretyData.inputAirlines(0x0000);
    } catch (error) {
        reverted = true;
    }
    assert.equal(reverted, true, "access is true for requireIsOperational");

    // Set it back for other tests to work

    await config.flightSuretyData.setOperatingStatus(true);

});


  it('Airline has been registered to data contract', async () => {
    let newAirline = accounts[2];

    try {
        await config.flightSuretyApp.turninRegistration(newAirline, {from: config.firstAirline});
        let registeredInd = await config.flightSuretyApp.receiveRegisteredInd.call(newAirline, {from: config.firstAirline});
        await config.flightSuretyApp.applyRegistration(registeredInd, {from: config.firstAirline});
    }
    catch(e) {
    }
    let result = await config.flightSuretyData.istheAirlineRegistered.call(newAirline);

    assert.equal(result, true, "airline is not able to register in contract");

  });



  it('(airline) has been funded & is registered', async () => {

    let newAirline = accounts[3];
    let fund = config.weiMultiple * 10;

    try {
        await config.flightSuretyApp.turninRegistration(newAirline, {from: config.firstAirline});
        let registeredInd = await config.flightSuretyApp.receiveRegisteredInd.call(newAirline);
        await config.flightSuretyApp.applyRegistration(registeredInd, {from: config.firstAirline});
        await config.flightSuretyApp.payAirline({from: newAirline, value: fund});
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirlineFunded.call(newAirline);

    assert.equal(result, true, "airline should not be able to register another airline if it hasn't provided funding yet");

  });



  it('(airline) has access to vote', async () => {

    let newAirline3 = accounts[4];
    let newAirline2 = accounts[5];
    let registeredInd2 = 0;

    //airline

    try {
        await config.flightSuretyApp.turninRegistration(newAirline3, {from: config.firstAirline});
        let registeredInd3 = await config.flightSuretyApp.receiveRegisteredInd.call(newAirline3);
        await config.flightSuretyApp.applyRegistration(registeredInd3, {from: config.firstAirline});

        await config.flightSuretyApp.turninRegistration(newAirline2, {from: config.firstAirline});
        registeredInd2 = await config.flightSuretyApp.receiveRegisteredInd.call(newAirline2);

        await config.flightSuretyApp.registerVotes(registeredInd2, {from: newAirline3});
    }
    catch(e) {
    }
    let result = await config.flightSuretyApp.receiveVotes.call(registeredInd2, {from: newAirline3});

    // ASSERT
    assert.equal(result, true, "airline should be able to vote for registration");

  });



  it('The airlines may vote for new regristration', async () => {

    let newAirline2 = accounts[2];
    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    let newAirline6 = accounts[6];

    try {
        await config.flightSuretyApp.turninRegistration(newAirline5, {from: config.firstAirline});
        let registeredInd5 = await config.flightSuretyApp.receiveRegisteredInd.call(newAirline5);

        await config.flightSuretyApp.applyRegistration(5, {from: config.firstAirline});
        await config.flightSuretyApp.turninRegistration(newAirline6, {from: config.firstAirline});

        let registeredInd6 = await config.flightSuretyApp.receiveRegisteredInd.call(newAirline6);

        await config.flightSuretyApp.registerVotes(registeredInd6, {from: newAirline3});
        await config.flightSuretyApp.registerVotes(registeredInd6, {from: newAirline4});
        await config.flightSuretyApp.registerVotes(registeredInd6, {from: newAirline5});

        await config.flightSuretyApp.applyRegistration(registeredInd6, {from: config.firstAirline});

    }
    catch(e) {
    }

    let result = await config.flightSuretyData.istheAirlineRegistered.call(newAirline6);

     // ASSERT
     assert.equal(result, true, "The airline is not registered");

  });


  it ('Able to register flight in data contract', async () => {

    let result = true;

    try {
    await config.flightSuretyApp.registertheFlight('Test Flight #1', new Date().getTime(), {from: config.firstAirline});
    await config.flightSuretyApp.registertheFlight('Test Flight #2', new Date().getTime(), {from: config.firstAirline});

    } catch(e) {
        result = false;
    }

    //ASSERT

    assert.equal(result, true, "Flight has been registered");

  });

  it ('Received Updated Flights', async () => {

    let results = await config.flightSuretyApp.receiveUpdatedFlights();
    assert.equal(results.length, 2, 'Only 2 flight should be registered');

  });

  it('Flight Information Received', async () => {
    let flights = await config.flightSuretyApp.receiveUpdatedFlights();
    let results = await config.flightSuretyApp.getFlightInformation(flights[0]);
    assert.equal(results[0], 'Test Flight #1', 'These flights does correlate');
});

});
