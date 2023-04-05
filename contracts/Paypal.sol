// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Paypal {
    // Define the owner of the contract
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Create the Struct and Mapping for request, transaction, and name
    struct request {
        address requestor;
        uint256 amount;
        string message;
        string name;
    }

    struct sendReceive {
        string action;
        uint256 amount;
        string message;
        address otherPartyAddress;
        string otherPartyName;
    }

    struct userName {
        string name;
        bool hasName;
    }

    // Mappings
    mapping(address => userName) names;
    mapping(address => request[]) requests;
    mapping(address => sendReceive[]) history;

    // Functions

    // Add a name to wallet address

    function addName(string memory _name) public {
        userName storage newUserName = names[msg.sender];
        newUserName.name = _name;
        newUserName.hasName = true;
    }

    // Create a request

    function createRequest(
        address user,
        uint256 _amount,
        string memory _message
    ) public {
        request memory newRequest;
        newRequest.requestor = msg.sender;
        newRequest.amount = _amount;
        newRequest.message = _message;
        if (names[msg.sender].hasName) {
            newRequest.name = names[msg.sender].name;
        }
        requests[user].push(newRequest);
    }

    // Pay a request
    function payRequest(uint256 _request) public payable {
        // Make sure request id is valid
        require(_request < requests[msg.sender].length, "Invalid request");
        // generate a request
        request[] storage myRequests = requests[msg.sender];
        request storage payableRequest = myRequests[_request];

        uint256 toPay = payableRequest.amount * 10 ** 18;
        require(msg.value == (toPay), "You must pay the correct amount");

        payable(payableRequest.requestor).transfer(msg.value);

        addHistory(
            msg.sender,
            payableRequest.requestor,
            payableRequest.amount,
            payableRequest.message
        );

        myRequests[_request] = myRequests[myRequests.length - 1];
        myRequests.pop();
    }

    function addHistory(
        address sender,
        address receiver,
        uint256 _amount,
        string memory _message
    ) private {
        sendReceive memory newSend;
        newSend.action = "-";
        newSend.amount = _amount;
        newSend.message = _message;
        newSend.otherPartyAddress = receiver;
        if (names[receiver].hasName) {
            newSend.otherPartyName = names[receiver].name;
        }
        history[sender].push(newSend);

        // Create a new receive invoice
        sendReceive memory newReceive;
        newReceive.action = "+";
        newReceive.amount = _amount;
        newReceive.message = _message;
        newReceive.otherPartyAddress = sender;
        if (names[sender].hasName) {
            newReceive.otherPartyName = names[sender].name;
        }
        history[receiver].push(newReceive);
    }

    // Get all the requests sent to the user
    function getMyRequests(
        address _user
    )
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            string[] memory,
            string[] memory
        )
    {
        address[] memory addresses = new address[](requests[_user].length);
        uint256[] memory amounts = new uint256[](requests[_user].length);
        string[] memory messages = new string[](requests[_user].length);
        string[] memory names = new string[](requests[_user].length);

        for (uint i = 0; i < requests[_user].length; i++) {
            addresses[i] = requests[_user][i].requestor;
            amounts[i] = requests[_user][i].amount;
            messages[i] = requests[_user][i].message;
            names[i] = requests[_user][i].name;
        }

        return (addresses, amounts, messages, names);
    }

    // Get all historic transactions user has been a part of

    function getMyHistory(
        address _user
    ) public view returns (sendReceive[] memory) {
        return history[_user];
    }

    function getMyName(address _user) public view returns (userName memory) {
        return names[_user];
    }
}
