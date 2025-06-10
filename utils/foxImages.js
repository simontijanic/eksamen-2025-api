// Hjelpefunksjoner for å generere og validere fox image IDs og URLs

const MAX_FOX_ID = 123;

function getRandomFoxId(excludeId = null) {
    let id;
    do {
        id = Math.floor(Math.random() * MAX_FOX_ID) + 1;
    } while (id === excludeId); // hvis du passer inn et excludeId så vil det ikke bli valgt
    // Dette sikrer at vi ikke får samme ID som allerede er valgt
    return id;
}

function getFoxImageUrl(id) {
    return `https://randomfox.ca/images/${id}.jpg`;
}

module.exports = {
    MAX_FOX_ID,
    getRandomFoxId,
    getFoxImageUrl
};
