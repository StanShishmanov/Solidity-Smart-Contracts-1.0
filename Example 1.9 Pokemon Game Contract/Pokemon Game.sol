pragma solidity >=0.5.1 <0.6.0;
/** @title Pokemon Game Contract */
contract PokemonGame {                                              // Declaration of Auction contract

    enum Pokemons {Abomasnow, Barbaracle, Cascoon, Corviknight, Dragonite, Emboar, Floatzel, Golisopod, Helioptile, Infernape}
    
    struct Player {                                                 // Player struct
        Pokemons[] pokemons;                                        // Each player can have multiple pokemons
        uint timeLimit;                                             // Keeps track of time
    }
    
    mapping(address => mapping(uint => bool)) isCaught;             // Keeps track of whether a player has caught a pokemon
    mapping(address => Player) players;                             // Keeps track of players
    mapping(uint => address[]) haveCaught;                          // Keeps track which players have caught a specific pokemon
    
    event LogPokemonCaught(address _from, Pokemons _pokemon, uint _time);
    
    /** @dev                    Function to catch pokemons
     *                          Each player can only catch a pokemon every 15 seconds.
     * 
     *  @param _pokemon         Needed to choose a pokemon to be caught
     */
    function catchPokemon(Pokemons _pokemon) public {
       require(players[msg.sender].timeLimit + 15 seconds < now, "You can catch a Pokemon every 15 seconds.");
       
       uint pokemonId = uint(_pokemon);
       
       require(!isCaught[msg.sender][pokemonId], "You have already caught this Pokemon.");
       haveCaught[pokemonId].push(msg.sender);
       players[msg.sender].pokemons.push(_pokemon); 
       
       isCaught[msg.sender][pokemonId] = true;
       players[msg.sender].timeLimit = now;
       
       emit LogPokemonCaught(msg.sender, _pokemon, now);
    }
    /** @dev                    A function to return all pokemons of a player.
     * 
     *  @param _player          The player's address.
     * 
     *  @return                 Returns a list of all user's caught pokemons.
     */
    function getPokemons(address _player) public view returns (Pokemons[] memory _pokemons) {
        return players[_player].pokemons;
    }
    
    /** @dev                    A function to return all players which caught a specific pokemon.
     * 
     *  @param _pokemon         The pokemon's id.
     * 
     *  @return                 Returns a list of all players addresses which caught a specific pokemon.
     */
    function getPokemonOwners(Pokemons _pokemon) public view returns (address[] memory _players) {
        uint pokemonId = uint(_pokemon);
        return haveCaught[pokemonId];
    }
}