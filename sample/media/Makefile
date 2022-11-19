DL = curl -sSf -o $@
YTDL = yt-dlp -o $@
DLV = $(YTDL) -S codec,+size
DLA = $(YTDL) -x --audio-format opus

media: utrecht-pub.jpg nyan.gif taddy-skates.webm serbia-bike.webm alugalug-intl.webm

utrecht-pub.jpg:
	# https://www.flickr.com/photos/albatz/25540736521
	$(DL) https://live.staticflickr.com/1502/25540736521_b42ff96bc8_c.jpg

nyan.gif:
	# https://prguitarman.tumblr.com/post/4281177195
	$(DL) https://64.media.tumblr.com/tumblr_lj0wls8poh1qb9bjho1_400.gifv

taddy-skates.webm:
	$(DLV) https://www.youtube.com/watch?v=YiE8V7sqjvw

serbia-bike.webm:
	$(DLV) https://www.youtube.com/watch?v=uAV2XE1d2Bo # 1bike1world

alugalug-intl.opus:
	$(DLA) https://www.youtube.com/watch?v=S61ENc51Z1Q # The Kiffness
