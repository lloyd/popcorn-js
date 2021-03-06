test( "Popcorn lower third Plugin", function () {
  
  var popped = Popcorn( "#video" ),
      expects = 8, 
      count = 0,
      lowerthirddiv = document.getElementById( "lowerthirddiv" );

  expect(expects);
  
  function plus() {
    if ( ++count===expects ) {
      start();
    }
  }
  
  stop();
   
  ok ( "lowerthird" in popped, "lowerthird is a method of the popped instance" );
  plus();
  
  equals ( lowerthirddiv.innerHTML, "", "initially, there is nothing inside the lowerthirddiv" );
  plus();

  ok( !popped.container, "initially, there is no default div" );
  plus();
  
  // empty track events should be safe
  popped.lowerthird({});

  // debug should log errors on error track events
  Popcorn.plugin.debug = true;
  try {
    popped.lowerthird({
      target: "does not exist"
    });
  } catch( e ) {
    ok(true, 'invalid target event was caught by debug');
    plus();
  }

  popped.lowerthird({
      start: 0, // seconds
      end: 2, // seconds
      salutation: "Mr",
      name: "Hyde",
      role: "Monster"
    } )
    .lowerthird({
      start: 2, // seconds
      end: 4, // seconds
      target: "lowerthirddiv",
      salutation: "Dr",
      name: "Jekyll",
      role: "Person"
    } )
    .volume(0);
    
  popped.exec( 1, function() {
    equals ( popped.container.innerHTML, "Mr Hyde<br>Monster", "first lowerthird is visible" );
    plus();
  });
  
  popped.exec( 3, function() {
    equals ( lowerthirddiv.innerHTML, "<div>Dr Jekyll<br>Person</div>", "second lowerthird is visible" );
    plus();
  });
  
  popped.exec( 5, function() {
    equals ( popped.container.innerHTML, "", "first lowerthird is empty" );
    plus();
    equals ( lowerthirddiv.innerHTML, "<div></div>", "second lowerthird is empty" );
    plus();
  });
  
  popped.play();

});
