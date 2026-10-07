// Requires Fengari (npm package); run from the Workshop project root.
const fs = require('fs');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const translationRoot = 'Contents/mods/ApocalipseBRRadio/common/media/lua/shared/Translate';
const catalogs = ['EN', 'PTBR'].map(language =>
    JSON.parse(fs.readFileSync(`${translationRoot}/${language}/RadioData.json`, 'utf8')));
if (JSON.stringify(catalogs[0]) !== JSON.stringify(catalogs[1])) {
    throw new Error('Both active game languages must include the same broadcast variants');
}
for (const [index, catalog] of catalogs.entries()) {
    const state = lauxlib.luaL_newstate();
    lualib.luaL_openlibs(state);
    lua.lua_newtable(state);
    for (const [key, value] of Object.entries(catalog)) {
        if (typeof value !== 'string') throw new Error(`Non-string translation: ${key}`);
        const partner = key.endsWith('_EN') ? key.replace(/_EN$/, '_PTBR') : key.replace(/_PTBR$/, '_EN');
        const placeholders = text => (text.match(/%[1-9]/g) || []).sort().join(',');
        if (!(partner in catalog) || placeholders(value) !== placeholders(catalog[partner])) {
            throw new Error(`Missing language variant or mismatched placeholders: ${key}`);
        }
        lua.lua_pushstring(state, to_luastring(value));
        lua.lua_setfield(state, -2, to_luastring(key));
    }
    lua.lua_setglobal(state, to_luastring('RadioTranslationCatalog'));
    if (lauxlib.luaL_dofile(state, to_luastring('tests/translations_spec.lua')) !== lua.LUA_OK) {
        throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
    }
    lua.lua_close(state);
    console.log(`${['EN', 'PTBR'][index]} dictionary: catalog, channel mapping, formatting and fallback passed`);
}
