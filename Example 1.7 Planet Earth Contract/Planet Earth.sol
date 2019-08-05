pragma solidity >=0.5.1 <0.6.0;
pragma experimental ABIEncoderV2;

/** @title PlanetEarth*/
contract PlanetEarth {                                                  // Declaration of Crowdsale contract
    
    enum Continents { Antarctica, Africa, Asia, Australia, Europe, North_America, South_America } 
    
    struct Country {                                                    // A struct with all country's properties
        bytes32 name;                                                   // Name of a country
        Continents continent;                                           // The continent of a country
        uint population;                                                // Population of a country
    }
    
    Country[] countries;                                                // An array of countries structs

    mapping(bytes32 => bool) public isCapital;                          // Checks whether a capital has been used
    
    mapping(bytes32 => bytes32) public capitals;                        // Connects a country to a capital
    
    event LogAddedCountry(bytes32 name, Continents continent, uint population);
    event LogAddedCapital(bytes32 capitalName, bytes32 countryName);
    
    modifier onlyEuropean(uint8 _continent) {
        require(_continent == uint8(Continents.Europe), "Only european countries can be added.");
        _;
    }
    
    /** @dev                        Adds a country.
     * 
     *  @param _name                Hex of the country's name.
     *  @param _continent           Only allows a country from the european continent.
     *  @param _population          The country's population.
     */
    function addCountry(bytes32 _name, uint8 _continent, uint _population) public onlyEuropean(_continent) {
        
        Country memory newCountry = Country(_name, Continents.Europe, _population);
        countries.push(newCountry);
        emit LogAddedCountry(_name, Continents.Europe, _population);
    }
    
    /** @dev                        A function to add a capital linked to a country.
     *  
     *  @param _countryName         A hex of the country's name.
     *  @param _capital             A hex of the capital's name.
     */ 
    function addCapital(bytes32 _countryName, bytes32 _capital) public {
        require(!isCapital[_capital], "This capital is already linked to a country.");
        capitals[_countryName] = _capital;
        isCapital[_capital] = true;
        
        emit LogAddedCapital(_capital, _countryName);
    }
    
    /** @dev                        A function to return a string representation of a capital by a given country name.
     *                              This function converts the byte32 value of the capital into a string.
     *  @param _countryName         A hex of the country's name is used to return a string.
     *  @return string              Returns a string representation of the hex value of the capital.
     */
    function getCapital(bytes32 _countryName) public view returns (string memory) {
        
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = capitals[_countryName][i];
        }
        return string(bytesArray);
    }
    /** @dev                        A function to remove a capital off a list of capitals.
     *                          
     *  @param _countryName         A parameter used to find which capital must be deleted.
     * 
     *                              Although nothing is ever deleted from a blockchain, this is one way to do it.
     */
    function removeCapital(bytes32 _countryName) public {
        isCapital[_countryName] = false;
        delete capitals[_countryName];
    }
    
    /** @dev                    A function to return a string representation of a continent by entering a number between 0 and 6.
     *  
     *  @param _continent       A number used for returning a string representation.
     *  @return                 Returns a string representation of a continent.
     */
    function getAContinent(uint8 _continent) public pure returns (string memory _cont) {
        require(_continent <= 6, "Use a number between 0 and six.");
        if(_continent == 0) {
            _cont = "Antarctica";
        } else if(_continent == 1) {
            _cont = "Afrika";
        } else if(_continent == 2) {
            _cont = "Asia";
        } else if(_continent == 3) {
            _cont = "Australia";
        } else if(_continent == 4) {
            _cont = "Europe";
        } else if(_continent == 5) {
            _cont = "North_America";
        } else if(_continent == 6) {
            _cont = "South_America";
        }
        return _cont;
    }
    /** @dev            Function to return all european countries.
     * 
     *  @return         Returns an array of the countries' struct
     *                  At the moment there is no easy workaroud when returning an array of structs.
     *                  pragma experimental ABIEncoderV2 is the fastest and so far cheapest way to return struct array.
     *                  Every other workaround needs a for loop and makes too many network calls, 
     *                  ofter resulting in consuming all of the gas.
     */
    function getAllEuropeanCountries1() public view returns (Country[] memory) {
        return countries;
    }
    // Helper hexes :)
    
    // Bulgaria
    // 0x42756c6761726961000000000000000000000000000000000000000000000000
    // Sofia
    // 0x536f666961000000000000000000000000000000000000000000000000000000
    
    // Romania
    // 0x526f6d616e696100000000000000000000000000000000000000000000000000
    // Bucharest
    // 0x4275636861726573740000000000000000000000000000000000000000000000
}