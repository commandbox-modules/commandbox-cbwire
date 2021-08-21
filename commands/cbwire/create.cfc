/**
 * Creates a cbwire component in an existing ColdBox application.
 *
 * Make sure you are running this command at the root of your app to find the correct folder.
 * Components will be created in the /wires folder by default.
 *
 **/
component {

    /**
     * @name Name of the component to create without the .cfc.
     * @actions Comma-delimited list of actions to generate.
     * @views Generate a view for the cbwire component.
     * @viewsDirectory Directory where your views are stored. Only used if views is set to true.
     * @integrationTests Generate the integration test component
     * @testsDirectory Your integration tests directory. Only used if integrationTests is true
     * @directory Base directory to create your handler in and creates the directory if it does not exist. Defaults to 'handlers'.
     * @description Component hint description.
     * @open Opens the component (and test(s) if applicable) once generated.
     **/
    function run(
        required name,
        actions = "",
        boolean views = true,
        viewsDirectory = "views/wires",
        boolean integrationTests = true,
        testsDirectory = "tests/specs/integration/wires",
        directory = "wires",
        description = "I am a new cbwire component.",
        boolean open = false
    ){
        // This will make each directory canonical and absolute
        arguments.directory = resolvePath( arguments.directory );
        arguments.viewsDirectory = resolvePath( arguments.viewsDirectory );
        arguments.testsDirectory = resolvePath( arguments.testsDirectory );

        // Validate directory
        if ( !directoryExists( arguments.directory ) ){
            directoryCreate( arguments.directory );
        }

        // Allow dot-delimited paths
        arguments.name = replace( arguments.name, ".", "/", "all" );
        // This help readability so the success messages aren't up against the previous command line
        print.line();

        /*******************************************************************
         * Read in Templates
         *******************************************************************/

        var handlerContent = fileRead( "wireContent.txt" );
        var actionContent = fileRead( "actionContent.txt" );
        var wireTestContent = fileRead( "wireBDDContent.txt" );
        var wireTestCaseContent = fileRead( "wireBDDCaseContent.txt" );

        // Start text replacements
        handlerContent = replaceNoCase(
            handlerContent,
            "|handlerName|",
            arguments.name,
            "all"
        );
        wireTestContent = replaceNoCase(
            wireTestContent,
            "|handlerName|",
            arguments.name,
            "all"
        );
        handlerContent = replaceNoCase(
            handlerContent,
            "|Description|",
            arguments.description,
            "all"
        );

        handlerContent = replaceNoCase(
            handlerContent,
            "|viewPath|",
            "wires/" & lCase( arguments.name ),
            "all"
        );

        viewContent = "<cfoutput><div>whatever</div></cfoutput>";

        // Handle Actions if passed
        if ( len( arguments.actions ) ){
            var allActions = "";
            var allTestsCases = "";
            var thisTestCase = "";

            // Loop Over actions generating their functions
            for ( var thisAction in listToArray( arguments.actions ) ){
                thisAction = trim( thisAction );
                allActions = allActions & replaceNoCase(
                    actionContent,
                    "|action|",
                    thisAction,
                    "all"
                ) & cr & cr;

                // Are we creating tests cases on actions
                if ( arguments.integrationTests ){
                    thisTestCase = replaceNoCase(
                        wireTestCaseContent,
                        "|action|",
                        thisAction,
                        "all"
                    );
                    thisTestCase = replaceNoCase(
                        thisTestCase,
                        "|event|",
                        listChangeDelims( arguments.name, ".", "/\" ) & "." & thisAction,
                        "all"
                    );
                    allTestsCases &= thisTestCase & CR & CR;
                }
            }

            // final replacements
            allActions = replaceNoCase(
                allActions,
                "|name|",
                arguments.name,
                "all"
            );
            handlerContent = replaceNoCase(
                handlerContent,
                "|EventActions|",
                allActions,
                "all"
            );
            wireTestContent = replaceNoCase(
                wireTestContent,
                "|TestCases|",
                allTestsCases,
                "all"
            );
        } else{
            handlerContent = replaceNoCase(
                handlerContent,
                "|EventActions|",
                "",
                "all"
            );
            wireTestContent = replaceNoCase(
                wireTestContent,
                "|TestCases|",
                "",
                "all"
            );
        }

        createResource( "#arguments.directory#/#arguments.name#.cfc", handlerContent );

        if ( arguments.views ){
            createResource( arguments.viewsDirectory & "/" & lCase( arguments.name ) & ".cfm", viewContent );   
        }

        if ( arguments.integrationTests ){

            createResource( "#arguments.testsDirectory#/#arguments.name#Test.cfc", wireTestCaseContent );
            // open file
            if ( arguments.open ){
                openPath( testPath );
            }
        }

        // open file
        if ( arguments.open ){
            openPath( handlerPath );
        }
    }

    function createResource( path, content ){
        var resourcePath = resolvePath( arguments.path );

        // Create dir if it doesn't exist
        directoryCreate(
            getDirectoryFromPath( resourcePath ),
            true,
            true
        );

        // Confirm it
        if (
            fileExists( resourcePath ) && !confirm(
                "The file '#getFileFromPath( resourcePath )#' already exists, overwrite it (y/n)?"
            )
        ){
            print.redLine( "Exiting..." );
            return;
        }

        // Write out the files
        file action="write" file="#resourcePath#" mode="777" output="#content#";
        print.greenLine( "Created #resourcePath#" );
    }

}
