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

    function parse(tokens, errorField) {

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
            if("0123456789.".includes(currentCharacter))
            {
                // Numbers

                let numberToken = "" + currentCharacter;
                let decimalFlag = false;

                if(currentCharacter == '.')
                {
                    decimalFlag = true;
                }

                incrementCurrentCharacter();

                while("0123456789.".includes(currentCharacter))
                {
                    numberToken += currentCharacter;

                    if(currentCharacter == '.')
                    {
                        if(decimalFlag == true)
                        {
                            errorField.text = qsTr(`Extra period at position ${index+1}`);
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
                // examine; the for loop will increment it. Therefore,
                // it must be brought back by one
                index--;
            }
            else if("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(currentCharacter))
            {
                // Functions & Variables

                let stringToken = "" + currentCharacter;

                incrementCurrentCharacter();

                while("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".includes(currentCharacter))
                {
                    stringToken += currentCharacter;

                    incrementCurrentCharacter();
                }

                stringToken = stringToken.toLowerCase();

                if(stringToken === "sqrt" ||
                stringToken === "log" ||
                stringToken === "ln" ||
                stringToken === "sin":
                case "cos":
                case "tan":
                case "sinh":
                case "cosh":
                case "tanh":
                case "asin":
                case "acos":
                case "atan":
                case "abs":
                case "ceil":
                case "floor":
                case "sum":
                case "mult":
                default:
                }
            }

            // Operators

            // Punctuation

            // Whitespace

        }

        return tokens;
    }


    ComboBox {
        id: noteChooserBox
        model: [qsTr("Modify"), qsTr("Generate")]
    }

    TextField {
        id: keyField
        placeholderText: qsTr("Formula to determine key")

        onTextEdited:
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

        onClicked:
    }
}
