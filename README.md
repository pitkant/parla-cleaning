# Finnish Parliamentary Data cleaning scripts

This repository contains scripts used to clean Finnish Parliamentary Debate XML files.

The steps for running everything are as follows:

1.  Download Speeches data in XML format from [ParliamentSampo website](https://a3s.fi/parliamentsampo/speeches/xml/index.html). The XML files contain more information than the ready-made [CSV files](https://a3s.fi/parliamentsampo/speeches/csv/index.html) so it's worth taking a few extra steps to use those.

2.  Clean the files using finparl_xml_cleaner.sh script found in speechxml2csv folder. This makes each

    <note>

    and <u> xml:id attribute unique and in line with XML specifications, which state that xml:id shouldn't start with numbers. The script also adds a segment id at the end of the xml:id pattern, if it didn't exist already. An example of how the script changes fields:

From:

```         
<note link="https://www.eduskunta.fi/FI/Vaski/sivut/trip.aspx?triptype=ValtiopaivaAsiakirjat&amp;docid=ptk+1/2003" multilingual="false" speechType="PuhemiesPuheenvuoro" type="speaker" xml:id="2003_1_1" xml:lang="fi"/>

<u ana="#elderMember" who="#Kalevi_Lamminen" xml:id="2003_1_1">Toimitetaan nimenhuuto työjärjestyksen 2 §:ssä tarkoitetun luettelon mukaan. Pyydän, että edustajat nimenhuudossa seisomaan nousten kuuluvasti vastaavat, kun heidän nimensä huudetaan.</u>
```

To:

```         
<note link="https://www.eduskunta.fi/FI/Vaski/sivut/trip.aspx?triptype=ValtiopaivaAsiakirjat&amp;docid=ptk+1/2003" multilingual="false" speechType="PuhemiesPuheenvuoro" type="speaker" xml:id="FI2003_1_1" xml:lang="fi"/>

<u ana="#elderMember" who="#Kalevi_Lamminen" xml:id="FI2003_1_1.1">Toimitetaan nimenhuuto työjärjestyksen 2 §:ssä tarkoitetun luettelon mukaan. Pyydän, että edustajat nimenhuudossa seisomaan nousten kuuluvasti vastaavat, kun heidän nimensä huudetaan.</u>
```

3. Use parla_cleaning.R to clean each year's speech dataset. This is done by splitting the dataset into two: unilingually Finnish speeches into one pipeline and multilingually Finnish and Swedish speeches and unilingually Swedish speeches into another pipeline. Unilingually Finnish speeches can be handled with a simpler process by using a trankit pipeline that has unilingually Finnish language detection. Multilingual and Swedish speeches are split into individual sentences and language is determined for each sentence individually, not for each paragraph. Trankit would classify a whole paragraph or speech to be Finnish or Swedish, possibly based on which language its last words are in (?).

The Finnish dataset is handled on CSC Jupyter notebooks with GPU acceleration. The notebook has the following specifications:

````
partition: gpu
number of CPU cores: 8
memory (GB): 4
local disk (GB): 20
time: 4:00:00
python: pytorch
working directory: /scratch/project_xxxxxxx
enable user packages: true
user packages path: /projappl/project_xxxxxxx/my-python-env/lib/python3.9/site-packages
```

Zipped input_files.zip dataset is placed onto scratch project folder alongside parla_trankit.ipynb file. When the script is ready, the handled files are zipped into an output_files.zip file. When the Jupyter notebook is handling the dataset, the user can use the handle_parl function / script on his computer to handle the multilingual and Swedish texts.

The data is saved onto a database file. These individual database files are finally merged into one big database file by using parla_db_merging.R script.