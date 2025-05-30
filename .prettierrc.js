module.exports = {
    $schema: 'http://json.schemastore.org/prettierrc',
    tabWidth: 4,
    singleQuote: true,
    arrowParens: 'avoid',
    vueIndentScriptAndStyle: true,
    overrides: [
        {
            files: ['.prettierrc', '.eslintrc', 'package.json'],
            options: { parser: 'json' },
        },
    ],
    printWidth: 150,
    bracketSpacing: true,
};
