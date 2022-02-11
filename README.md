# XMLgen
generate commissioning in xml
*/*Version 20210801 (v1) */
*/*Version 20220102 (v2) - specify template & suffix for scf by fltemplate,scfSuffix in lnbts input */
*Usage: perl XMLgen2.pl -[hvrd] filenames
        -h      Usage guidelines
        -v      Development version
        -r      Generate template files
        -d      Output directory - without space in dir's path

Examples:> perl XMLgen.pl D:\data\lnbts.csv D:\data\lncel.csv D:\data\scf_config_template.xml
         > perl XMLgen.pl -r D:\data\Comm_scf.xm
