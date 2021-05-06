'use strict'

module.exports = {
    loadYml,
    loadConfig,
    template
};

// public
function loadYml(filePath) {
    const fs = require('fs');
    const jsyml = require('js-yaml');
    const ymlText = fs.readFileSync(filePath, 'utf-8');

    return jsyml.load(ymlText);
}

/**
 * loadConfig.
 *
 * @param {String} configPath
 * @return {Object}
 */
function loadConfig() {
    const configPath = 'config/config.yml';
    try {
        return loadYml(configPath);
    } catch (err) {
        console.error(err.message);
    }
}

/**
 * @see http://webdesign-dackel.com/2015/07/17/javascript-template-string/
 */
function template(string, values, opening, closing) {
    const CONFIG = loadConfig();
    opening = preg_quote(opening || CONFIG['TEMPLATE_DELIMITERS']['OPENING']);
    closing = preg_quote(closing || CONFIG['TEMPLATE_DELIMITERS']['CLOSING']);

    return string.replace(new RegExp(opening + "(.*?)" + closing, "g"), function(all, key){
        return Object.prototype.hasOwnProperty.call(values, key) ? values[key] : "";
    });
}

// private
/**
 * @see http://webdesign-dackel.com/2015/07/17/javascript-template-string/
 */
function preg_quote(str, delimiter){
    return String(str).replace(new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\' + (delimiter || '') + '-]', 'g'), '\\$&');
}

