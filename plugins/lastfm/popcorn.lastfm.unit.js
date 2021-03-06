test("Popcorn LastFM Plugin", function () {
  /*
    ATTENTION
  
    This demo uses an API key obtained for testing the LastFM Popcorn.js
    plugin. Please do not use it for other purposes.
  */
  var popped = Popcorn("#video"),
      expects = 10, 
      count = 0,
      setupId,
      lastfmdiv = document.getElementById('lastfmdiv');
  
  expect( expects );
  
  function plus() {
    if ( ++count === expects) {
      start();
    }
  }

  stop();   
 
  ok('lastfm' in popped, "lastfm is a method of the popped instance");
  plus();

  equals ( lastfmdiv.innerHTML, "", "initially, there is nothing inside the lastfmdiv" );
  plus();
  
  popped.lastfm({
    start: 1, // seconds
    end: 4, // seconds
    artist: 'yacht',
    target: 'lastfmdiv',
    apikey: '30ac38340e8be75f9268727cb4526b3d'
  })
  .lastfm({
    start: 2, // seconds
    end: 7, // seconds
    artist: 'the beatles',
    target: 'lastfmdiv',
    apikey: '30ac38340e8be75f9268727cb4526b3d'
  })
  .lastfm({
    start: 4, // seconds
    end: 7, // seconds
    target: 'lastfmdiv',
    apikey: '30ac38340e8be75f9268727cb4526b3d'
  });

  setupId = popped.getLastTrackEventId();

  popped.exec( 2, function() {
    equals ( lastfmdiv.childElementCount, 3, "lastfmdiv now has three inner elements" );
    plus();
    equals (lastfmdiv.children[0].style.display , "inline", "yachtdiv is visible on the page" );
    plus();
  });

  popped.exec( 3, function() {
    equals (lastfmdiv.children[0].style.display , "inline", "yachtdiv is still visible on the page" );
    plus();
    equals (lastfmdiv.children[1].style.display , "inline", "beatlesdiv is visible on the page" );
    plus();
    equals (lastfmdiv.children[2].style.display , "none", "nulldiv is not visible on the page" );
    plus();
  });

  popped.exec( 5, function() {
    equals (lastfmdiv.children[2].innerHTML , "Unknown Artist", "Artist information could not be found" );
    plus();

    popped.pause().removeTrackEvent( setupId );
    ok( !lastfmdiv.children[2], "removed artist was properly destroyed" );
    plus();
  });

  // empty track events should be safe
  popped.lastfm({});

  // debug should log errors on empty track events
  Popcorn.plugin.debug = true;
  try {
    popped.lastfm({});
  } catch( e ) {
    ok(true, 'empty event was caught by debug');
    plus();
  }
  
  popped.volume(0).play();
});
