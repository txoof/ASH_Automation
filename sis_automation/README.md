# sis_automation

Reports to be used in SIS Automation

## new_students

Locate new students and provide a template that can be used for updating Google accounts and PowerSchool data.

## Updating and Packaging Plugin

### Potential Pitfalls

Problems that have been encountered while developing plugins.

#### Query Name

The `name` portion of each query/permission file should be in reverse DNS dotted format. It appears that it should always be in the format `tld.domain.pluginname.queryname`. Deviating from this causes plugin errors on installation. If `queryname` is longer than about 12 characters, this can also cause errors on plugin installation.

#### coreTable

Each query should have a coreTable set. Pick `STUDENTS` or `CC` to be on the safe side. This has very little impact on the actual functioning of the plugin. `¯\_(ツ)_/¯`

#### Column Definitions

The Column Definitions in the XML must:

* Match the number of columns returned in the `select` portion of the query
* Match the order of the columns returned in the `select` portion of the query
* Match columns in the "core" tables and fields of PowerSchool
  * `STUDENTS.ID` is always a safe choice
* **NEVER** contain a space; see column definitions example below
  * The plugin can be installed, it will load load, Data Export Manager exports will function, but any saved template based on a plugin that uses a space will fail to load and work properly `¯\_(ツ)_/¯`

Column definition examples:

```xml
<!--BAD-->
<column column="STUDENTS.ID">Student_Number</column>
<!--GOOD-->
<column column="STUDENTS.ID">Student_Number</column>
```

#### permissions_root

Each query needs a matching `permission_mappings.xml` file. Each file should:

* Match exactly the name of the query file
  * e.g. `queries_root/foo_spam.named_queries.xml` `permissions_root/foo_spam.permission_mappinsg.xml`
* Contain the exact same reverse DNS dotted name as the query within the `<implies>` statement

#### plugin.xml

The `plugin.xml` file must:

* Contain a version number > the currently installed plugin version
* Not contain any characters other than `[0-9.]` in the version number
* Not change the name of the plugin (this will cause the plugin to be rejected as an update)

### Packaging

Packaging & upgrade checklist:

* [ ] Bump version number in `plugin.xml` -- updates with version numbers <= to installed version will be rejected
* [ ] Create a flat zip file that contains the appropriate files with no parent folder -- see the `package.sh` script below
* [ ] Upload the .zip file through the PowerSchool Plugin Management screen
* [ ] Enable the plugin after upload
* [ ] Verify that no errors were generated

package.sh script:

Usage: `package.sh [directory containing plugin files]`

```shell
package.sh sis_automation
```

### Basic Structure

Plugins are FLAT zip files that follow the structure shown below:

```text
├── permissions_root
│   └── my_custom_query.permission_mappings.xml
└── queries_root
    ├── my_custom_query.named_queries.xml
    └── other_report.named_queries.xml
```

Including any other files will throw an error when installing the plugin.

#### plugin.xml

The [plugin.xml](./plugin.xml) describes the plugin, maintainer and version number. When a plugin is updated, the version number must be positively incremented. If the plugin version number is equal or lower, PowerSchool will refuse to install the plugin.

Any major changes to the plugin name requires that the plugin is uninstalled completely and reinstalled.

#### queries_root

All queries are stored in this directory, one file for each Named Query

Queries are structured as follows:

```XML
<queries> 
    <!--set name here (also applies to permissions_root)-->
    <!--name: use reverse DNS dotted name in the format shown below-->
    <!--coreTable: can be any table, but should represent the primary table-->
    <!--flattened: ???no idea what this does???-->
    <query name="foo.spamham.pluginname.queryname" coreTable="students" flattened="false">
        <!--add description here-->
        <description>new students</description>
        <!--number of columns here must match number sql select statement returns-->
        <columns>
            <!--column="TABLE.FIELD" this doesn't actually matter much in practice-->
            <!-->this name appears as the default header on the output report<-->
            <<!--NEVER EVER EVER USE A SPACE IN THE COLUMN HEADER this will break the template manager in Data Export Manager-->
            <column column="STUDENTS.ID">Student_Number</column> <!-- for columns not in database use a core filed-->
         </columns>
        <!--SQL query in format <![CDATA[QUERY]]>-->
        <sql>
            <![CDATA[
            select
                students.student_number,
                
            from 
                students students,
            where
                and students.enroll_status in(1)
            -- according to the spec, this is required, in practice, it is not needed
            order by
                students.student_number asc
            ]]>
        </sql>
    </query>
</queries>
```

#### permissions_root

Permissions set here are mapped from user permissions. If the user has the appropriate privileges to  access a page listed in the `permission_mappings.xml` file, they should be able to run the associated named query. See this [blog post](https://cookbrianj.wordpress.com/2017/01/23/plugin-export-with-ps-dem/) for more information on permission mappings.

Permission mapping file names must match the query filename:

* Query filename: foo.named_queries.xml
* Permission Mapping filename: foo.permission_mappings.xml

Permission mappings are structured as follows:

```XML
<permission_mappings>
  <!--Anyone that has access to the following page can run this query-->
  <permission name='/admin/home.html'>
  <!--.../query/BASE_PLUGIN should be identical to `name` in named_queries.xml-->
 <implies allow="post">/ws/schema/query/foo.spamham.pluginname.queryname</implies>
  </permission>
</permission_mappings>
```

# BS_07_Users_Teachers

Powerschool &rarr; BrightSpace CSV x for 00-xx

**PROVIDES FIELDS:**

`xx` used in 6-Sections as `yyy`

|Field |Format |example |
|:-|:-|:-|
|`xx`| `foo_`_`cc.bar`_| foo_bar

**USES FIELDS:**

`xx` from [foo]() as `yyy`

## Data Export Manager

* **Category:** Show All
* **Export Form:**  tld.domain.product.area.name

### Lables Used on Export

| Lable |
|-|
|foo|
|ID|
|LAST_NAME|

### Export Summary and Output Options

#### Export Format

* _Export File Name:_ `BASE_PLUGIN.csv`
* _Line Delimiter:_ `CR-LF`
* _Field Delimiter:_ `,`
* _Character Set:_ TBD

#### Export Options

* _Include Column Headers:_ `True`
* _Surround "field values" in Quotes:_ TBD

## Query Setup for `named_queries.xml`

### PowerQuery Output Columns

| header | table.field | value | NOTE |
|-|-|-|-|
|foo| STUDENTS.ID | user | N1 |
|ID| STUDENTS.ID |_SIS student number_ |
|last_name| STUDENTS.LAST_NAME |_SIS Last Name_ |

#### Notes

**N1:** Field does not appear in database; use a known field such as `<column column=STUDENT.ID>header<\column>` to prevent an "unknown column error"

### Tables Used

| Table |  |
|-|-|
|STUDENTS| |

### SQL

```
select 
   'foo' as "bar",
   STUDENTS.ID as ID,
STUDENTS.LAST_NAME as LAST_NAME 
from STUDENTS STUDENTS 
where STUDENTS.ENROLL_STATUS =0
```
