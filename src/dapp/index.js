
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
//import BigNum from "bignumber";

const contract = new Contract('localhost');
let blockNumbersSeen = [];

(async() => {
    await contract.initWeb3(eventHandler);
    await getOperationalStatus();


    DOM.elid('update-status').addEventListener('click', refreshStatus);
    DOM.elid('set-contractApp-false').addEventListener('click', setOperationalStatusFalseApp);
    DOM.elid('set-contractData-false').addEventListener('click', setOperationalStatusFalse);
    DOM.elid('set-contractData-true').addEventListener('click', setOperationalStatusTrue);
    DOM.elid('input-airline').addEventListener('click', inputAirline);
    DOM.elid('register-votes').addEventListener('click', registerVotes);
    DOM.elid('apply-registration').addEventListener('click', applyRegistration);
    DOM.elid('pay-airline').addEventListener('click', payAirline);
    DOM.elid('register-flight').addEventListener('click', registerFlight);
    DOM.elid('purchase-flight-insurance').addEventListener('click', purchaseInsurance);
    DOM.elid('send-to-oracles').addEventListener('click', sendToOracles);
    DOM.elid('collect-funds').addEventListener('click', collectFunds);


})();

const collectFunds = async () => {
    await contract.payoutFunds();
}

const sendToOracles = async () => {
    const flightSelect = DOM.elid('select-flight');
    await contract.getFlightStatus(flightSelect.value);
    await refreshStatus();
}

const purchaseInsurance = async () => {
    const flightSelect = DOM.elid('select-flight');
    await contract.purchaseInsurance(flightSelect.value);
    await refreshStatus();
}

const registerFlight = async () => {
    const registerFlightName = DOM.elid('register-flight-name');
    const registerFlightDate = DOM.elid('register-flight-date');
    const registerFlightTime = DOM.elid('register-flight-time');
    const stringDate = `${registerFlightDate.value}T${registerFlightTime.value}Z`;
    const flightDateTime = new Date(stringDate).getTime();
    await contract.registerFlight(registerFlightName.value, flightDateTime);
    await refreshStatus();
};

const payAirline = async () => {
    await contract.payAirline();
    await refreshStatus();
};

const inputAirline = async () => {
    const element = DOM.elid('submit-airline-address');
    await contract.inputAirline(element.value);
    await refreshStatus();
    element.value = '';
};

const registerVotes = async () => {
    const element = DOM.elid('voting-airline-address');
    await contract.registerVotes(element.value);
    await refreshStatus();
    element.value = '';
};

const applyRegistration= async () => {
    const element = DOM.elid('executing-airline-address');
    await contract.applyRegistration(element.value);
    await refreshStatus();
    element.value = '';
};

const setOperationalStatus = async (enabled) => {
    await contract.setOperationalStatus(enabled);
    await refreshStatus();
}

const setOperationalStatusFalse = async () => {
    await setOperationalStatus(false);
}

const setOperationalStatusTrue = async () => {
    await setOperationalStatus(true);
}

const setOperationalStatusFalseApp = async () => {
    await contract.setOperationalStatusApp(false);
    await refreshStatus();
}

async function getOperationalStatus() {
    let contractIsOperational;
    let amountofAirlines;
    let contractBalance;

    try {
        contractIsOperational = await contract.isOperational();
    } catch (error) {
        contractIsOperational = "Error!";
        console.log(error);
    }

    try {
        amountofAirlines = await contract.amountofAirlines();
    } catch (error) {
        amountofAirlines = "Error!";
        console.log(error);
    }

    try {
        contractBalance = await contract.getContractBalance();
    } catch (error) {
        contractBalance = "Error!";
        console.log(error);
    }

    await removeAllChildren('operational-status');

    await display('operational-status', 'Operational Status', 'Status of contract', [
        {label: 'Operational Status:', value: contractIsOperational},
        {label: 'Number of registered airlines:', value: amountofAirlines},
        {label: 'Contract Balance:', value: contractBalance},
        {label: 'Last updated:', value: new Date()}
    ]);

    try {
        await removeAllChildren('voting-airline-address');
        let receivePurposedAirlines = await contract.receivePurposedAirlines();
        const currentFlightSelect = DOM.elid('voting-airline-address');
        for (let index = 0; index < receivePurposedAirlines.length; index++) {
            let receiveAppliedRegristration = await contract.receiveAppliedRegristration(index);
            let option = document.createElement('option');
            option.append(`${receiveAppliedRegristration}`)
            option.value = receiveAppliedRegristration;

            currentFlightSelect.append(option);
        }
    } catch (error) {
        console.log(error);
    }

    try {
        await removeAllChildren('select-flight');
        let receiveUpdatedFlights = await contract.receiveUpdatedFlights();
        const currentFlightSelect = DOM.elid('select-flight');
        for (let index = 0; index < receiveUpdatedFlights.length; index++) {
            let receiveUpdatedFlights = await contract.receiveUpdatedFlights(receiveUpdatedFlights[index]);
            let option = document.createElement('option');
            option.append(`${new Date(new BigNumber(receiveUpdatedFlights[1]).toNumber()).toISOString()} ${receiveUpdatedFlights[0]}`)
            option.value = receiveUpdatedFlights[index];

            currentFlightSelect.append(option);
        }
    } catch (error) {
        console.log(error);
    }
}

const refreshStatus = async () => {
    await getOperationalStatus();
}

const removeAllChildren = async (parent) => {
    let displayDiv = DOM.elid(parent);
    while (displayDiv.firstChild) {
        displayDiv.removeChild(displayDiv.firstChild);
    }
}

const display = async (divid, title, description, results) => {
    let displayDiv = DOM.elid(divid);
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className: 'row text-white'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);
}

function eventHandler(error, event) {
    if (blockNumbersSeen.indexOf(event.transactionHash) > -1) {
        blockNumbersSeen.splice(blockNumbersSeen.indexOf(event.transactionHash), 1);
        return;
    }
    blockNumbersSeen.push(event.transactionHash);
    console.log(event.address);

    const log = DOM.elid('log-ul');
    let newLi1 = document.createElement('li');
    newLi1.append(`${event.event} - ${event.transactionHash}`);
    log.appendChild(newLi1);
}
