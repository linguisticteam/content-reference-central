<?php

class ErrorTemplate {
    private $category;    // Category number
    private $number;      // Number in category
    private $technical;   // Short technical information
    private $description; // Expanded information for user

    private $file;        // File name where error occurred
    private $line;        // Line number in file where error occurred

    /* Constructors */

    public function __construct($category,$number,$technical,$description) {
        $this->category    = $category;
        $this->number      = $number;
        $this->technical   = $technical;
        $this->description = $description;
        $this->file        = "";
        $this->line        = 0;
    }

    /* Set Functions */

    public function SetFile($file) {
        $this->file = $file;
    }

    public function SetLine($line) {
        $this->line = $line;
    }

    /* Get Functions */

    public function GetCategory() {
        return $this->category;
    }

    public function GetNumber() {
        return $this->number;
    }

    public function GetTechnical() {
        return $this->technical;
    }

    public function GetDescription() {
        return $this->description;
    }

    public function GetFile() {
        return $this->file;
    }
    
    public function GetLine() {
        return $this->line;
    }

    /* Info Retrieving Functions */

    public function TechnicalDataToString() {
        $compiled_string = "Error#" .
            $this->category .
            "-" .
            $this->number .
            ":" .
            $this->technical .
            "\n" .
            "File: '" .
            $this->file .
            "'\n" .
            "Line: " .
            $this->line .
            "\n";

        return $compiled_string;
    }

    public function GetDescription() {
        return $this->description;
    }
}

class Error {

    /* Static Members */

    private static $templates = array();
    private static $raised_errors = array();

    /* Constructors */

    public function __construct() {

        if (!$this->is_initialized()) {

            $this->create_templates();
        }
    }

    /* Initialization Functions */

    // Get count of templates to see if class is initialized
    private function is_initialized() {

        if (count(self::$templates)) {

            return FALSE;
        }

        return TRUE;
    }

    // Create templates
    private function create_templates() {

        // Errors in PHP (Category#00):

        // Errors in data convention (Category#01):
        self::$templates['ContainsComma']              = new ErrorTemplate(01,01,"TECHNICAL","Resource Author Name contains reserved character: ','");
        self::$templates['SelectAuthorType']           = new ErrorTemplate(01,02,"TECHNICAL","Please select an Author Type");
        self::$templates['SpecifyResourceAuthor']      = new ErrorTemplate(01,03,"TECHNICAL","Please specify a Resource Author");
        self::$templates['TitleAlreadyExists']         = new ErrorTemplate(01,04,"TECHNICAL","A resource with this title already exists");
        self::$templates['TitleNotSpecified']          = new ErrorTemplate(01,05,"TECHNICAL","Resource title is not specified");
        self::$templates['KeywordsAreRequired']        = new ErrorTemplate(01,06,"TECHNICAL","Please specify some keywords");
        self::$templates['AuthorTypeIncorrectValue']   = new ErrorTemplate(01,07,"TECHNICAL","Author Type is an incorrect value");
        self::$templates['SelectResourceType']         = new ErrorTemplate(01,08,"TECHNICAL","Please select a Resource Type");
        self::$templates['ResourceTypeIncorrectValue'] = new ErrorTemplate(01,09,"TECHNICAL","Resource Type is an incorrect value");
        self::$templates['SpecifyResourceURL']         = new ErrorTemplate(01,10,"TECHNICAL","Please specify a URL for the Resource");
        self::$templates['ProvideDescription']         = new ErrorTemplate(01,11,"TECHNICAL","Please provide a description");
        
        // Errors when interacting with database (Category#02):
        //self::$templates['CannotConnectToDB']        = new ErrorTemplate(02,01,"TECHNICAL","Could not connect to database: " . mysqli_errno($connection));
        self::$templates['GetTypesMethodFailed']       = new ErrorTemplate(02,01,"Database->GetTypes() failed","DESCRIPTION");
        
        // Errors when calling stored procedure in database (Category#03):
        self::$templates['spf_insert_authors']         = new ErrorTemplate(03,01,"Stored Procedure Failed: insert_authors","DESCRIPTION");
        self::$templates['spf_insert_resource']        = new ErrorTemplate(03,02,"Stored Procedure Failed: insert_resource","DESCRIPTION");
        self::$templates['spf_insert_keywords']        = new ErrorTemplate(03,03,"Stored Procedure Failed: insert_keywords","DESCRIPTION");
    }

    /* Public Functions */

    public function raise($file,$line,$error_key) {

        $error_to_raise = self::$templates[$error_key];

        $error_to_raise->SetFile($file);
        $error_to_raise->SetLine($line);

        self::$raised_errors[] = $error_to_raise;
    }

    public function clear_all() {

        self::$raised_errors = array();
    }

    public function count() {

        return count(self::$raised_errors);
    }

    public function print_all() {

        foreach (self::$raised_errors as $error) {

            echo($error->TechnicalDataToString());
            echo($error->GetDescription());
        }
    }
}