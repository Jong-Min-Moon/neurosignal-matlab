la = longtermAnalyzer()
%organ, ch, month
ch111 = channel("ch6.csv", 1, 1, 1)
ch111.bandPass([300,3000]);
ch111.detectSpikes(5,2,2);

ch122 = channel("ch6.csv", 1, 2, 2)
ch122.bandPass([300,1000]);
ch122.detectSpikes(5,2,2);

ch211 = channel("ch6.csv", 2, 1, 1)
ch211.bandPass([300,1500]);
ch211.detectSpikes(5,2,2);

ch222 = channel("ch6.csv", 2, 2, 2)
ch222.bandPass([300,2000]);
ch222.detectSpikes(5,2,2);

ch311 = channel("ch6.csv", 3, 1, 2)
ch311.bandPass([300,1300]);
ch311.detectSpikes(5,2,2);

ch322 = channel("ch6.csv", 2, 1, 2)
ch322.bandPass([300,600]);
ch322.detectSpikes(5,2,2);

la.addChannel(ch111)
la.addChannel(ch122)
la.addChannel(ch211)
la.addChannel(ch222)
la.addChannel(ch311)
la.addChannel(ch322)

la.drawHistByMonth(1)