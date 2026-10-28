import MuseScore
import QtQuick
import QtQuick.Controls

MuseScore {
    id: root
    title: "Mathodeon"
    description: qsTr("Tool for composing music with mathematical formulas")
    version: "1.0"
    pluginType: "dialog"


    onRun: {}

    property string keyFormula: "p"
    property string pitchFormula: "p"
    property string timingFormula: "p"
    property string durationFormula: "p"
    property string velocityFormula: "p"

    property Object key: ({})
    property Object pitch: ({})
    property Object timing: ({})
    property Object duration: ({})
    property Object velocity: ({})


    /*
             * Formula grammar in Backus-Naur Form,
             * (using regular expression notation in expressions to shorten
             *  the text)
             *
             * <S> ::= <P> (<B> <P>)*
             * <P> ::= <V> | "(" <S> ")" | "-" <P> | <F> "(" <S> ")" |
             * 		   <T> "(" <E><A>* "," <S> "," <S> ")"
             * <B> ::= "=" | "!=" | ">" | "<" | "+" | "-" | "*" | "/" | "^"
             * <F> ::= "log" | "ln" | "sin" | "cos" | "tan" | "sinh" | "cosh" |
             * "tanh" | "asin" | "acos" | "atan" | "sqrt"| "ceil" | "floor" |
             * "abs"
             * <T> ::= "sum" | "mult"
             * <V> ::= <E><A>* | <D>*.?<D>*
             * <E> ::= [a-z|A-Z]
             * <D> ::= [0-9]
             * <A> ::= [a-z|A-Z|0-9]
             */

    function checkFormula(tokens, errorField) {

        function expect(testee, expectedToken) {
            if(testee === expectedToken)
            {
                return;
            } else {
                if(expectedToken.level === 9)
                {
                    errorField.text = "Open parenthese is not closed";
                } else {
                    errorField.text = "Unexpected symbol : expected " + expectedToken.element +
                            ", got " + testee.element + " instead.";
                }
            }
        }

        function s(tokens, index, errorField) {

            p(tokens, index, errorField);

            let next = index < tokens.length - 1 ? tokens[index++]: tokens[index];

            while(index < tokens.length - 1 &&
                  (next.level > 1 && next.level < 6))
            {
                p(tokens, index, errorField);
                next = index < tokens.length - 1 ? tokens[index++]: tokens[index];
            }

            return next;
        }

        function p(tokens, index, errorField) {

            const openParentheseToken = {element: "(", level:8};
            const commaToken = {element: ",", level:10};
            const closeParentheseToken = {element: ")", level:9};


            let next;

            function iterate(error){
               if(index < tokens.length - 1)
               {
                   next = tokens[index++];
               } else {
                   errorField.text = error;
               }
            }

            iterate("Unexpected end of formula");

            if(next.level === 0)
            {
                return;
            } else if(next.element === "sum" || next.element === "mult")
            {
                iterate("Unexpected end of formula");
                expect(next, openParentheseToken);
                iterate("Unexpected end of formula");
                if(next.level !== 1)
                {
                    errorField.text = "Unexpected symbol " + next.element
                            + "; expected a variable";
                }
                iterate("Unexpected end of formula");
                expect(next, commaToken);
                next = s(tokens, index, errorField);
                expect(next, commaToken);
                next = s(tokens, index, errorField);
                expect(next, closeParentheseToken);
            } else if(next.element === "(")
            {
                next = s(tokens, index, errorField);
                expect(next, closeParentheseToken);
            } else if(next.element === "-")
            {
                tokens[index-1] = {element: "--", level: 6};
                p(tokens, index, errorField);
            } else if (next.level === 7)
            {
                iterate("Unexpected end of formula");
                expect(next, openParentheseToken);
                next = s(tokens, index, errorField);
                expect(next, closeParentheseToken);
            } else
            {
                errorField.text = "Unexpected symbol " + next.element;
            }
        }

        let token = s(tokens, 0, errorField);

        if(token.level !== 11)
        {
            errorField.text = "Unexpected symbol: " + token.element;
        }

        return errorField.text === ""? tokens: [];
    }

    function makePostFix(tokens) {

        return tokens;
    }

    function buildOperationsTree(tokens, parameter) {


    }


    function parse(parameter, parameterField, errorField) {

        errorField.text = "";

        let tokens = tokenize(parameterField.text, errorField);

        tokens = checkFormula(tokens, errorField);

        if(tokens.length > 0)
        {
            tokens = makePostFix(tokens);
            buildOperationsTree(tokens, parameter);
            checkVariables(parameter);
        }


    }

    function tokenize(formula, errorField) {

        /*
         * TABLE OF ACCEPTABLE TOKENS
         * Numbers: [0-9]*.?[0-9]*
         * Functions: "sqrt", "log", "ln", "sin", "cos", "tan", "sinh", "cosh", "tanh",
                      "asin", "acos", "atan", "abs", "ceil", "floor", "sum", "mult"
         * Variables: [A-Za-z]*[A-Za-z0-9]*
         * Operators: "!", "!=", "=", ">", ">=", "<", "<=", "+", "-", "*", "/", "%", "^"
         * Punctuation: "(", ")", ","
        */


        formula.trim();

        let tokens = Array();
        let index = 0;
        let currentCharacter = formula.charAt(index);

        function incrementCurrentCharacter() {
            index++;
            currentCharacter = formula.charAt(index);
        }

        for(index; index < formula.length(); index++)
        {
            if("0123456789.".includes(currentCharacter)) // Tokenizing Numbers
            {
                let numberToken = "" + currentCharacter;
                let decimalFlag = false;

                if(currentCharacter === '.')
                {
                    decimalFlag = true;
                }

                incrementCurrentCharacter();

                while("0123456789.".includes(currentCharacter))
                {
                    numberToken += currentCharacter;

                    if(currentCharacter === '.')
                    {
                        if(decimalFlag == true)
                        {
                            errorField.text = qsTr(`Extra period at position ${index}`);
                            return;
                        } else
                        {
                            decimalFlag = true;
                        }
                    }

                    incrementCurrentCharacter();
                }


                const token = {element: numberToken, level: 0};
                tokens.push(token);

                // index is currently on the next character we want to
                // examine due to incrementCurrentCharacter() pushing it
                // beyond numbers; the for loop will increment it even
                // further. Therefore, it must be brought back by one
                index--;
            }
            else if("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(currentCharacter))
            {
                // Tokenizing Functions & Variables

                let stringToken = "" + currentCharacter;

                incrementCurrentCharacter();

                while("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(currentCharacter))
                {
                    stringToken += currentCharacter;

                    incrementCurrentCharacter();
                }

                stringToken = stringToken.toLowerCase();

                if(stringToken === "sqrt" || stringToken === "log" ||
                    stringToken === "ln" || stringToken === "sin" ||
                    stringToken === "cos" || stringToken === "tan" ||
                    stringToken === "sinh" || stringToken === "cosh" ||
                    stringToken === "tanh" || stringToken === "asin" ||
                    stringToken === "acos" || stringToken === "atan" ||
                    stringToken === "abs" || stringToken === "ceil" ||
                    stringToken === "floor" || stringToken === "sum" ||
                    stringToken === "mult")
                {
                    const token = {element: stringToken, level: 7};
                    tokens.push(token);
                }
                else
                {
                    while("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(currentCharacter))
                    {
                        stringToken += currentCharacter;

                        incrementCurrentCharacter();
                    }

                    const token = {element: stringToken, level: 1};
                    tokens.push(token);

                    // index is currently on the next character we want to
                    // examine due to incrementCurrentCharacter() pushing it
                    // beyond numbers or letters; the for loop will increment
                    // it even further. Therefore, it must be brought back by one
                    index--;
                }
            }
            else
            {
                switch(currentCharacter)
                {
                case '!':
                    if (formula.charAt(index+1) === '=')
                    {
                        const token = {element: "!=", level: 2}
                        tokens.push(token);

                        index++;
                    } else {
                        const token = {element: "!", level: 7}
                        tokens.push(token);
                    };
                    break;
                case '=':
                    const token = {element: "=", level: 2}
                    tokens.push(token);
                    break;
                case '>':
                case '<':
                    if (formula.charAt(index+1) === '=')
                    {
                        const token = {element: currentCharacter + "=", level: 2}
                        tokens.push(token);

                        index++;
                    } else {
                        const token = {element: "" + currentCharacter, level: 2}
                        tokens.push(token);
                    };
                    break;
                case '+':
                case '-':
                    const additionToken = {element: "" + currentCharacter, level: 3}
                    tokens.push(token);
                    break;
                case '*':
                case '/':
                case '%':
                    const multiplicationToken = {element: "" + currentCharacter, level: 4}
                    tokens.push(token);
                    break;
                case '^':
                    const exponentToken = {element: "^", level: 5}
                    tokens.push(token);
                    break;
                case '(':
                    const openParentheseToken = {element: "(", level: 8}
                    tokens.push(token);
                    break;
                case ')':
                    const closeParentheseToken = {element: ")", level: 9}
                    tokens.push(token);
                    break;
                case ',':
                    const commaToken = {element: ",", level: 10}
                    tokens.push(token);
                    break;
                case ' ':
                    break;
                default: errorField.text = qsTr("Untreatable character: "+currentCharacter + "; it cannot be processed.");
                }
            }

        }

        const lineToken = {element: "EOL", level: 11}
        tokens.push(token);

        return tokens;
    }


    ComboBox {
        id: noteChooserBox
        model: [qsTr("Modify"), qsTr("Generate")]
    }

    TextField {
        id: keyField
        placeholderText: qsTr("Formula to determine key")


    }

    TextField {
        id: pitchField
        placeholderText: qsTr("Formula to determine pitch")
    }

    TextField {
        id: timingField
        placeholderText: qsTr("Formula to determine when notes are played")
    }

    TextField {
        id: durationField
        placeholderText: qsTr("Formula to determine duration")
    }

    TextField {
        id: velocityField
        placeholderText: qsTr("Formula to determine velocity")
    }

    Button {
        id: runButton
        text: qsTr("Submit")


    }
}
