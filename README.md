# India ISIN Data

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6508187.svg)](https://doi.org/10.5281/zenodo.6508187) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/captn3m0/india-isin-data) ![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/captn3m0/india-isin-data) ![GitHub repo size](https://img.shields.io/github/repo-size/captn3m0/india-isin-data) [![Flat GitHub Badge](https://img.shields.io/badge/View_Data_on-Flat_Github-GREEN.svg)](https://flatgithub.com/captn3m0/india-isin-data)

ISIN Data from various public securities. You can sort and filter this dataset in your browser at https://flatgithub.com/captn3m0/india-isin-data.

Source: [NSDL Website Detailed ISIN Search][nsdl].

Automatically updated every midnight (IST).

**Note**: The [NSDL Website][nsdl] returns zero valid results for `INA, INB`, so those are not tracked.

# ISIN Structure

ISIN (International Securities Identification Number) is defined by [ISO 6166:2021][iso] and adopted in India by BIS as [IS 15415:2021][bis] ([(PDF)][bispdf]) ([(PDF2)](https://archive.org/details/gov.in.is.15415.2003)). ISINs in India are [allotted by NSDL for all securities except Government Securities](https://investor.sebi.gov.in/pdf/reference-material/ppt/PPT-7%20Depository%20Services.pdf) (See Page 9).

> This Indian Standard (Second Revision) which is identical with ISO 6166 : 2021 ‘Financial services - International securities identification number (ISIN)’ issued by the International Organization for Standardization (ISO) was adopted by the Bureau of Indian Standards on recommendation of the Banking and Financial Services Sectional Committee and approval of the Services Sector Division Council.

ISIN, as per the ISO standard consists of 3 parts:

1. **A 2 Character country code as prefix (ISO-3166)**. For ISINs issued in India, this will always be `IN`.
2. **A Basic Identification Number**. 9 alphanumeric characters left padded with zeroes.
3. **A check digit**.

The basic number in India is issued by NSDL and is composed of 4 parts:

1. A 1-character **Issuer-Type**. This varies from A-F/9.
1. A 4-character **Issuer code**. Alphanumeric.
1. A 2-character **Security Type**. Alphanumeric.
1. A 2-digit **serial number for the security itself**. Alphanumeric.

Hence, each issuer can issue 36^2 = 1296 securities under each type.  
The table below explains the same with an example:

<div>
<table>
	<tbody>
		<tr>
            <th>Field</th>
			<td colspan="2" style="text-align: center">Country Code</td>
			<td style="text-align: center">Issuer Type</td>
			<td style="text-align: center" colspan="4">Issuer Code</td>
			<td style="text-align: center" colspan="2">Security Type</td>
			<td style="text-align: center" colspan="2">Serial Number</td>
			<td style="text-align: center">Check Digit</td>
		</tr>
		<tr>
            <th>Index</th>
			<td style="text-align: center"><code>1</code></td>
			<td style="text-align: center"><code>2</code></td>
			<td style="text-align: center"><code>3</code></td>
			<td style="text-align: center"><code>4</code></td>
			<td style="text-align: center"><code>5</code></td>
			<td style="text-align: center"><code>6</code></td>
			<td style="text-align: center"><code>7</code></td>
			<td style="text-align: center"><code>8</code></td>
			<td style="text-align: center"><code>9</code></td>
			<td style="text-align: center"><code>10</code></td>
			<td style="text-align: center"><code>11</code></td>
			<td style="text-align: center"><code>12</code></td>
		</tr>
		<tr>
            <th>Class</th>
			<td style="text-align: center"><code>I</code></td>
			<td style="text-align: center"><code>N</code></td>
			<td style="text-align: center"><code>A-F,0-9</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>alpha</code></td>
			<td style="text-align: center"><code>0-9</code></td>
		</tr>
		<tr>
			<!-- IN F 789F 01 XA 0 -->
            <th>Sample</th>
			<td style="text-align: center"><code>I</code></td>
			<td style="text-align: center"><code>N</code></td>
			<td style="text-align: center"><code>F</code></td>
			<td style="text-align: center"><code>7</code></td>
			<td style="text-align: center"><code>8</code></td>
			<td style="text-align: center"><code>9</code></td>
			<td style="text-align: center"><code>F</code></td>
			<td style="text-align: center"><code>0</code></td>
			<td style="text-align: center"><code>1</code></td>
			<td style="text-align: center"><code>X</code></td>
			<td style="text-align: center"><code>A</code></td>
			<td style="text-align: center"><code>0</code></td>
		</tr>
	</tbody>
</table>
</div>

Here's the breakdown of the above ISIN (`INF789F01XA0`):

- Country Code: `IN`
- Issuer Type: `F` (Mutual Funds)
- Issuer Code: `789F` (UTI Mutual Fund)
- Security Type: `01` (Equity Shares)
- Serial Number: `XA`
- Check Digit: `0`

### Issuer Types

Issuer Type|Issuer Type Code
-----------|-------------
Central Government|`A`
State Government|`B`
Municipal Corporation|`C`
Union Territories|`D`
Company, Statutory Corporation, Banking Company|`E`
Mutual Funds|`F`
Partly Paid-up Shares|`G`
Central Government Security|`0`
State Government Security|`1`
State Government Security|`2`
State Government Security|`3`
State Government Security|`4`

### Issuer Code

Please see `issuers.csv` (🚧)


### Security Type

The security type is defined in the 8th and 9th character of the ISIN code. The same security type code can have different meanings against different issuers.

This table is based on analysis done on real data. A lot of categories (such as Bonds) are fluid, and the exact description in the dataset might not match the security type in this table (As an example the dataset might state "Deep Discount Bond" instead of "Bond". Note that some other sources on the Internet might differ with this table. If you find a ISIN that does not fit in the following table correctly, please create an issue with the ISIN.

Issuer Type | Security Type Code  |   Security Type
------------|--------|-----------------
Company (`INE`) | 01     |   Equity Share
Company (`IN9`) | 01     |   Equity Share
Mutual Fund (`INF`) | 01 |   Mutual Fund Unit
Company (`INE`) | 02     |   Postal Savings Scheme
Company (`INE`) | 03     |   Preference Share
Company (`IN9`) | 03     |   Preference Share
Company (`INE`) | 04     |   Preference Share
Company (`IN9`) | 04     |   Preference Share
Company (`INE`) | 05     |   Deep Discount Bond
Company (`INE`) | 06     |   Floating Rate Bond
Company (`INE`) | 07     |   Bond / Debenture
Company (`INE`) | 08     |   Bond / Debenture
Company (`INE`) | 09     |   Bond / Debenture
Company (`INE`) | 10     |   Floating Rate Bond
Company (`INE`) | 11     |   Bonds
Company (`INE`) | 13     |   Warrants
Company (`INE`) | 14     |   Commercial Paper
Company (`INE`) | 15     |   Securitised Instrument
Company (`INE`) | 16     |   Certificate of Deposit
Company (`INE`) | 18     |   Securitised Instrument
Company (`IN9`) | 19     |   Mutual Fund Unit
Company (`INF`) | 19     |   Mutual Fund Unit
Mutual Fund (`INF`) | 1A |   Mutual Fund Unit
Company (`INE`) | 20     |   Rights Entitlement
Company (`INE`) | 21     |   Indian Depository Receipt
Mutual Fund (`INF`) | 22 |   Alternate Investment Fund
Company (`INE`) | 23     |   Infrastructure Investment Trust
Company (`INE`) | 24     |   Municipal Bond
Company (`INE`) | 25     |   Real Estate Investment Trusts
Mutual Fund (`INF`) | A1 |   Mutual Fund Unit
Company (`INE`) | A7     |   Debenture
Mutual Fund (`INF`) | B1 |   Mutual Fund Unit
Company (`INE`) | B7     |   Debenture
Mutual Fund (`INF`) | C1 |   Mutual Fund Unit

### Check Digit

The last digit (check-digit) is calculated using the [Luhn Algorithm](https://en.wikipedia.org/wiki/Luhn_algorithm) with a slight change to accommodate alphanumeric characters. Alphabets are converted to digits by adding `9` to the usual numeric value of each letter. For example `A=10, B=12, C=13, ..., Z=35`. A few examples:

ISIN|Payload|Check Digit|Validate
----|-------|--------|---
`INE009A01021`|`18 23 14 009 10 0102`|`1`|[CyberChef](https://gchq.github.io/CyberChef/#recipe=Remove_whitespace%28%29Luhn_Checksum%28%29&input=MTggMjMgMTQgMDA5IDEwIDAxMDI)
`US0378331005`|`30 28 0378331001`|`5`|[CyberChef](https://gchq.github.io/CyberChef/#recipe=Remove_whitespace%28%29Luhn_Checksum%28%29&input=MzAgMjggMDM3ODMzMTAwMQ)
`AU0000XVGZA3`|`10 30 0000 33 31 16 35 10`|`3`|[CyberChef](https://gchq.github.io/CyberChef/#recipe=Remove_whitespace%28%29Luhn_Checksum%28%29&input=MTAgMzAgMDAwMCAzMyAzMSAxNiAzNSAxMA)
`INF789F01XA0`|`18 23 15 789 15 01 33 10`|`0`|[CyberChef](https://gchq.github.io/CyberChef/#recipe=Remove_whitespace%28%29Luhn_Checksum%28%29&input=MTggMjMgMTUgNzg5IDE1IDAxIDMzIDEw)

### References:

- https://www.basunivesh.com/how-your-dmat-mutual-funds-and-shares-isin-structured/
- https://theindianstockbrokers.com/what-is-isin-number-and-how-to-find-it/
- https://en.wikipedia.org/wiki/International_Securities_Identification_Number
- [ISO 6166][bispdf], Annex A.


# Code

You can run the following to generate the `ISIN.csv` file from scratch:

```
git clone https://github.com/captn3m0/india-isin-data.git
make check
make ISIN
```

## Dependencies:

- https://github.com/ericchiang/pup
- https://stedolan.github.io/jq/
- https://www.gnu.org/software/parallel/
- https://curl.se/
- https://www.gnu.org/software/sed/

# Alternative Sources

ISINs for India can be found at a few other sources:

- https://nsdl.co.in/downloadables/html/hold-mutual-fund-units.html
- [The Kuvera Mutual Fund Details API](https://stoplight.captnemo.in/docs/kuvera/reference/Kuvera.yaml/paths/~1mf~1api~1v4~1fund_schemes~1%7Bcodes%7D.json/get) returns ISIN codes.
- The [OpenFIGI API](https://www.openfigi.com/api) returns results for some (not all) Indian ISINs.
- The National Stock Exchange has [a few](https://www1.nseindia.com/products/content/debt/wdm/gsec_reporting_homepage.htm) [pages](https://www1.nseindia.com/products/content/debt/ncbp/ncbp_issues.htm) listing Government Security ISINs.
- Similarly, the Reserve Bank of India also lists Government Securities at a few pages: [[1]](https://www.rbi.org.in/Scripts/bs_viewcontent.aspx?Id=3876), [[2]](https://rbi.org.in/Scripts/bs_viewcontent.aspx?Id=1956), [[3](https://rbi.org.in/scripts/Bs_viewcontent.aspx?Id=3973)], [[4](https://rbi.org.in/scripts/BS_PressReleaseDisplay.aspx?prid=51712#AN1)], [[5](https://rbi.org.in/scripts/BS_PressReleaseDisplay.aspx?prid=52077)]. 

# License

Licensed under the [Creative Commons Zero v1.0 Universal](LICENSE) license. There are no guarantees made as to the correctness or accuracy of this data.

[nsdl]: https://nsdl.co.in/master_search.php
[iso]: https://www.iso.org/standard/78502.html
[bis]: https://www.services.bis.gov.in/php/BIS_2.0/bisconnect/ISL/is_details?IDS=NzUxNg%3D%3D
[bispdf]: https://law.resource.org/pub/in/bis/S07/is.15415.2003.pdf
