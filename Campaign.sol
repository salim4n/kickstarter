// SPDX-License-Identifier: MIT
// Indique la licence sous laquelle le code est distribué.

pragma solidity ^0.8.9;
// Définit la version minimale du compilateur Solidity requise pour le code.

contract CampaignFactory {
    address payable[] public deployedCampaigns;
    // Tableau dynamique contenant les adresses des campagnes déployées.

    function createCampaign(uint minimum) public {
        address newCampaign = address(new Campaign(minimum, msg.sender));
        // Crée une nouvelle instance de contrat Campaign.
        // `minimum` est le montant minimum de contribution requis pour la campagne.
        // `msg.sender` est l'adresse de l'appelant (celui qui déploie la campagne).
        
        deployedCampaigns.push(payable(newCampaign));
        // Ajoute l'adresse de la nouvelle campagne au tableau des campagnes déployées.
    }

    function getDeployedCampaigns() public view returns (address payable[] memory) {
        return deployedCampaigns;
        // Renvoie la liste des adresses des campagnes déployées.
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }
    // Structure pour représenter une demande de dépense au sein de la campagne.

    Request[] public requests;
    // Tableau dynamique contenant toutes les demandes de dépenses de la campagne.
    
    address public manager;
    // Adresse du gestionnaire de la campagne (celui qui l'a créée).
    
    uint public minimumContribution;
    // Montant minimum de contribution requis pour participer à la campagne.
    
    mapping(address => bool) public approvers;
    // Mapping pour suivre les contributeurs ayant approuvé la campagne.
    
    uint public approversCount;
    // Nombre total de contributeurs ayant approuvé la campagne.

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    // Modificateur qui restreint l'accès à certaines fonctions aux seuls gestionnaires de campagne.

    constructor (uint minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }
    // Constructeur pour initialiser les valeurs lors de la création de la campagne.

    function contribute() public payable {
        require(msg.value > minimumContribution);
        // Vérifie que la contribution est supérieure au montant minimum requis.

        approvers[msg.sender] = true;
        approversCount++;
        // Enregistre le contributeur et incrémente le compteur des contributeurs.
    }

    function createRequest(string memory description, uint value, address recipient) public restricted {
        Request storage newRequest = requests.push(); 
        newRequest.description = description;
        newRequest.value= value;
        newRequest.recipient= recipient;
        newRequest.complete= false;
        newRequest.approvalCount= 0;
    }
    // Crée une nouvelle demande de dépense pour la campagne restreinte aux gestionnaires.
    
    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }
    // Approuve une demande de dépense spécifique si le contributeur répond aux critères.

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        payable(request.recipient).transfer(request.value);
        request.complete = true;
    }
    // Finalise une demande de dépense si elle a suffisamment d'approbations.

    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }
    // Renvoie un résumé des informations de la campagne.

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
    // Renvoie le nombre total de demandes de dépenses créées.
}
