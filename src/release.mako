## Generates a single diff for a single row, ignoring the Status field
<%def name="singlediff(row)">
@@ ${row['key']}
%for k in row['changes']:
%if k != 'Status':
-${k}:${row['changes'][k][0]}
+${k}:${row['changes'][k][1]}
%endif
%endfor
</%def>

## Get description from a changed row
## Either from the changed or unchanged portion
<%def name="description(row)">
% if 'Description' in row['unchanged']:
${row['unchanged']['Description']}
%else:
${row['changes']['Description'][1]}
%endif
</%def>

<h2>Additions</h2>

The following new ISINs were added:

ISIN|Description|Issuer|Type|Status
----|-----------|------|---------------|------
% for row in added:
`${row['ISIN']}`|${row['Description']}|${row['Issuer']}|${row['Type']}|${row['Status'].title()}
% endfor

<h2>Changes</h2>

The following ISINs changed their status:

<table>
<thead>
	<tr>
		<th>ISIN</th>
		<th>Description</th>
		<th>Old Status</th>
		<th>New Status</th>
	</tr>
</thead>
<tbody>
% for row in changed:
% if 'Status' in row['changes']:
	<tr>
		<td><code>${row['key']}</code></td>
		<td>${description(row)}</td>
		<td>${row['changes']['Status'][0].title()}</td>
		<td>${row['changes']['Status'][1].title()}</td>
	</tr>
% endif
% endfor
</tbody>
</table>

## This will usually contain the description

The following ISINs changed other fields:

```diff
% for row in changed:
% if 'Status' not in row['changes']:
${singlediff(row)}
% endif
% endfor
```

## Removals are currently happening accidentally because NSDL website returns a 5xx

%if len(removed) > 0:

<h2>Removals</h2>

The following ISINs were completely removed (likely in error):

ISIN|Description|Issuer|Type|Status
----|-----------|------|---------------|------
% for row in removed:
`${row['ISIN']}`|${row['Description']}|${row['Issuer']}|${row['Type']}|${row['Status'].title()}
% endfor

%endif