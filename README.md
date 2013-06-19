# groupit

Web interface for a simple customized string clustering application. Try it at http://groupit-ruby.herokuapp.com.

Uses a [scluster](https://github.com/laurita/scluster) gem for string clustering. Before the clustering is performed, data cleaning is done. It includes separation of people and companies based on a custom regexp, emoving postcodes, company types and performing the clustering on the set of company strings.

The cluster names are predicted based on the longest common substring of all the strings in the cluster.