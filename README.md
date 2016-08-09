# Common docker image for NLB

An all-round [docker](https://www.docker.com/) image usable for most of NLBs book production workflow.
The latest pre-built image is available from docker hub as [nlbdev/docker-nlb-base](https://hub.docker.com/r/nlbdev/docker-nlb-base/).

* [XML Calabash](https://xmlcalabash.com/)
* [Saxon](http://saxon.sourceforge.net/)
* [mp3splt](http://mp3splt.sourceforge.net/)
* [DAISY Pipeline](http://www.daisy.org/pipeline)
* [DAISY Pipeline 2](http://www.daisy.org/pipeline2)
* [Filibuster TTS](https://no.wikipedia.org/wiki/Den_syntetiske_stemmen_Brage) and the norwegian voice Brage
    - Voice data is not included in the image to limit its size.
    - Mount the voice data as a volume by adding to your docker run: `-v "$RECS":"/mnt/filibuster-recs":ro`, where `$RECS` is for instance `/home/user/filibuster-recs`.
    - Filibuster output is stored as `/tmp/out.wav`, so for testing you can mount `/tmp` somewhere so that you can retrieve the file from the host. For instance, create `/tmp/filibuster` on the host and use: `-v "/tmp/filibuster":"/tmp"`
    - Voice data is not included in the image to limit its size. To download the voice data, run this on the host:
```
wget -O - https://gitlab.com/nlbdev/filibuster-brage/raw/develop/get-recs.sh | bash
```

* [calibre](http://calibre-ebook.com/) (TODO)
* [Braille in DAISY Pipeline 2](https://github.com/snaekobbi/) (TODO)

