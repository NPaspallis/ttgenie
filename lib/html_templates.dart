class HtmlTemplates {
static const String htmlTable = r'''
<html lang="en">

<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
}
tr {
  page_break_inside: avoid;
}
</style>

<body>

<h1>Teaching Staff per Programme of Study: %programme%</h1>

<table border="1">
    <tr>
        <th rowspan="2">#</th>
        <th rowspan="2">Name</th>
        <th rowspan="2">Qualifications</th>
        <th rowspan="2">Expertise</th>
        <th rowspan="2">Programme</th>
        <th colspan="2">Module</th>
        <th rowspan="2">Periods / Week</th>
        <th rowspan="2">Total</th>
    </tr>
    <tr>
        <th>Code</th>
        <th>Name</th>
    </tr>
    %rows%
</table>

<br>

</body>
</html>''';

  static const String htmlTableRowAcademic = r'''
    <tr>
        <td rowspan="%num_of_all_modules%">%num%</td>
        <td rowspan="%num_of_all_modules%">%name%</td>
        <td rowspan="%num_of_all_modules%">%qualifications%</td>
        <td rowspan="%num_of_all_modules%">%expertise%</td>
        <td rowspan="%num_of_programme_modules%">%programme%</td>
        <td>%module_code%</td>
        <td>%module_name%</td>
        <td>%module_hours%</td>
        <td rowspan="%num_of_all_modules%">%total_hours%</td>
    </tr>''';

  static const String htmlTableRowOtherProgs = r'''
    <tr>
        <td rowspan="%num_of_other_modules%">Other Programmes</td>
        <td>%module_code%</td>
        <td>%module_name%</td>
        <td>%module_hours%</td>
    </tr>''';

  static const String htmlTableRowModule = r'''
    <tr>
        <td>%module_code%</td>
        <td>%module_name%</td>
        <td>%module_hours%</td>
    </tr>''';
}
