// PLUGIN: OPENMAP
( function ( Popcorn ) {
  
  /**
   * openmap popcorn plug-in 
   * Adds an OpenLayers map and open map tiles (OpenStreetMap [default], NASA WorldWind, or USGS Topographic)
   * Based on the googlemap popcorn plug-in. No StreetView support
   * Options parameter will need a start, end, target, type, zoom, lat and lng
   * -Start is the time that you want this plug-in to execute
   * -End is the time that you want this plug-in to stop executing 
   * -Target is the id of the DOM element that you want the map to appear in. This element must be in the DOM
   * -Type [optional] either: ROADMAP (OpenStreetMap), SATELLITE (NASA WorldWind / LandSat), or TERRAIN (USGS).  ROADMAP/OpenStreetMap is the default.
   * -Zoom [optional] defaults to 2
   * -Lat and Lng are the coordinates of the map if location is not named
   * -Location is a name of a place to center the map, geocoded to coordinates using TinyGeocoder.com
   * -Markers [optional] is an array of map marker objects, with the following properties:
   * --Icon is the URL of a map marker image
   * --Size [optional] is the radius in pixels of the scaled marker image (default is 14)
   * --Text [optional] is the HTML content of the map marker -- if your popcorn instance is named 'popped', use <script>popped.currentTime(10);</script> to control the video
   * --Lat and Lng are coordinates of the map marker if location is not specified
   * --Location is a name of a place for the map marker, geocoded to coordinates using TinyGeocoder.com
   *  Note: using location requires extra loading time, also not specifying both lat/lng and location will
   * cause a JavaScript error. 
   * @param {Object} options
   * 
   * Example:
     var p = Popcorn( '#video' )
        .openmap({
          start: 5,
          end: 15,
          type: 'ROADMAP',
          target: 'map',
          lat: 43.665429,
          lng: -79.403323
        })
   *
   */
  var newdiv,
      i = 1;

  function toggle( container, display ) {
    if ( container.map ) {
      
      container.map.div.style.display = display;
      return;
    }

    setTimeout(function() {
      toggle( container, display );
    }, 10 );
  }

  Popcorn.plugin( "openmap", function( options ){
    var newdiv,
        centerlonlat,
        projection,
        displayProjection,
        pointLayer,
        selectControl,
        popup,
        isGeoReady,
        target = document.getElementById( options.target );

    // create a new div within the target div
    // this is later passed on to the maps api
    newdiv = document.createElement( "div" );
    newdiv.id = "openmapdiv" + i;
    newdiv.style.width = "100%";
    newdiv.style.height = "100%";
    i++;

    if ( !target && Popcorn.plugin.debug ) {
      throw new Error( "target container doesn't exist" );
    }

    target && target.appendChild( newdiv );

    // callback function fires when the script is run
    isGeoReady = function() {
      if ( !window.OpenLayers ) {
        setTimeout(function() {
          isGeoReady();
        }, 50);
      } else {
        if ( options.location ) {
          // set a dummy center at start
          location = new OpenLayers.LonLat( 0, 0 );
          // query TinyGeocoder and re-center in callback
          Popcorn.getJSONP(
            "http://tinygeocoder.com/create-api.php?q=" + options.location + "&callback=jsonp",
            function( latlng ) {
              centerlonlat = new OpenLayers.LonLat( latlng[1], latlng[0] );
              options.map.setCenter( centerlonlat );
            }
          );
        } else {
          centerlonlat = new OpenLayers.LonLat( options.lng, options.lat );
        }
        options.type = options.type || "ROADMAP";
        if ( options.type === "SATELLITE" ) {
          // add NASA WorldWind / LANDSAT map
          options.map = new OpenLayers.Map( { div: newdiv, "maxResolution": 0.28125, tileSize: new OpenLayers.Size( 512, 512 ) } );
          var worldwind = new OpenLayers.Layer.WorldWind( "LANDSAT", "http://worldwind25.arc.nasa.gov/tile/tile.aspx", 2.25, 4, { T: "105" } );
          options.map.addLayer( worldwind );
          displayProjection = new OpenLayers.Projection( "EPSG:4326" );
          projection = new OpenLayers.Projection( "EPSG:4326" );
        }
        else if ( options.type === "TERRAIN" ) {
          // add terrain map ( USGS )
          displayProjection = new OpenLayers.Projection( "EPSG:4326" );
          projection = new OpenLayers.Projection( "EPSG:4326" );
          options.map = new OpenLayers.Map( {div: newdiv, projection: projection } );
          var relief = new OpenLayers.Layer.WMS( "USGS Terraserver", "http://terraserver-usa.org/ogcmap.ashx?", { layers: 'DRG' } ); 
          options.map.addLayer( relief );
        } else {
          // add OpenStreetMap layer
          projection = new OpenLayers.Projection( 'EPSG:900913' );
          displayProjection = new OpenLayers.Projection( 'EPSG:4326' );
          centerlonlat = centerlonlat.transform( displayProjection, projection );
          options.map = new OpenLayers.Map( { div: newdiv, projection: projection, "displayProjection": displayProjection } );
          var osm = new OpenLayers.Layer.OSM();
          options.map.addLayer( osm );
        }
        if ( options.map ) {
          options.map.div.style.display = "none";
        }
      }
    };
    
    isGeoReady();

    return {
    
      /**
       * @member openmap 
       * The setup function will be executed when the plug-in is instantiated 
       */
      _setup: function( options ) {
      
        // insert openlayers api script once
        if ( !window.OpenLayers ) {
          Popcorn.getScript( "http://openlayers.org/api/OpenLayers.js" );
        }
      
        var isReady = function() {
          // wait until OpenLayers has been loaded, and the start function is run, before adding map
          if ( !options.map ) {
            setTimeout(function() {
              isReady();
            }, 13 );
          } else {
          
            // default zoom is 2
            options.zoom = options.zoom || 2;
            
            // make sure options.zoom is a number
            if ( options.zoom && typeof options.zoom !== "number" ) {
              options.zoom = +options.zoom;
            }

            // reset the location and zoom just in case the user played with the map
            options.map.setCenter( centerlonlat, options.zoom );
            if ( options.markers ) {
              var layerStyle = OpenLayers.Util.extend( {} , OpenLayers.Feature.Vector.style[ 'default' ] ),
                  featureSelected = function( clickInfo ) {
                    clickedFeature = clickInfo.feature;
                    if ( !clickedFeature.attributes.text ) {
                      return;
                    }
                    popup = new OpenLayers.Popup.FramedCloud(
                      "featurePopup",
                      clickedFeature.geometry.getBounds().getCenterLonLat(),
                      new OpenLayers.Size( 120, 250 ),
                      clickedFeature.attributes.text,
                      null,
                      true,
                      function( closeInfo ) {
                        selectControl.unselect( this.feature );
                      }
                    );
                    clickedFeature.popup = popup;
                    popup.feature = clickedFeature;
                    options.map.addPopup( popup );
                  }, 
                  featureUnSelected = function( clickInfo ) {
                    feature = clickInfo.feature;
                    if ( feature.popup ) {
                      popup.feature = null;
                      options.map.removePopup( feature.popup );
                      feature.popup.destroy();
                      feature.popup = null;
                    }
                  },
                  gcThenPlotMarker = function( myMarker ) {
                    Popcorn.getJSONP(
                      "http://tinygeocoder.com/create-api.php?q=" + myMarker.location + "&callback=jsonp",
                      function( latlng ) {
                        var myPoint = new OpenLayers.Geometry.Point( latlng[1], latlng[0] ).transform( displayProjection, projection ),
                            myPointStyle = OpenLayers.Util.extend( {}, layerStyle );
                        if ( !myMarker.size || isNaN( myMarker.size ) ) {
                          myMarker.size = 14;
                        }
                        myPointStyle.pointRadius = myMarker.size;
                        myPointStyle.graphicOpacity = 1;
                        myPointStyle.externalGraphic = myMarker.icon;
                        var myPointFeature = new OpenLayers.Feature.Vector( myPoint, null, myPointStyle );
                        if ( myMarker.text ) {
                          myPointFeature.attributes = { 
                            text: myMarker.text
                          };
                        }
                        pointLayer.addFeatures( [ myPointFeature ] );
                      }
                    );
                  };
              pointLayer = new OpenLayers.Layer.Vector( "Point Layer", { style: layerStyle } );
              options.map.addLayer( pointLayer ); 
              for ( var m = 0, l = options.markers.length; m < l ; m++ ) {
                var myMarker = options.markers[ m ];
                if( myMarker.text ){
                  if( !selectControl ){
                    selectControl = new OpenLayers.Control.SelectFeature( pointLayer );
                    options.map.addControl( selectControl );
                    selectControl.activate();
                    pointLayer.events.on({
                      "featureselected": featureSelected,
                      "featureunselected": featureUnSelected
                    });
                  }
                }
                if ( myMarker.location ) {
                  var geocodeThenPlotMarker = gcThenPlotMarker;
                  geocodeThenPlotMarker(myMarker);
                } else {
                  var myPoint = new OpenLayers.Geometry.Point( myMarker.lng, myMarker.lat ).transform( displayProjection, projection ),
                      myPointStyle = OpenLayers.Util.extend( {}, layerStyle );
                  if ( !myMarker.size || isNaN( myMarker.size ) ) {
                    myMarker.size = 14;
                  }
                  myPointStyle.pointRadius = myMarker.size;
                  myPointStyle.graphicOpacity = 1;
                  myPointStyle.externalGraphic = myMarker.icon;
                  var myPointFeature = new OpenLayers.Feature.Vector( myPoint, null, myPointStyle );
                  if ( myMarker.text ) {
                    myPointFeature.attributes = { 
                      text: myMarker.text
                    };
                  }
                  pointLayer.addFeatures( [ myPointFeature ] );
                }
              }
            }
          }
        };
        
        isReady();
      },
      
      /**
       * @member openmap 
       * The start function will be executed when the currentTime 
       * of the video  reaches the start time provided by the 
       * options variable
       */
      start: function( event, options ) {
        toggle( options, "block" );
      },
      
      /**
       * @member openmap
       * The end function will be executed when the currentTime 
       * of the video reaches the end time provided by the 
       * options variable
       */
      end: function( event, options ) {
          toggle( options, "none" );        
      },
      
      _teardown: function( options ) {

        target && target.removeChild( newdiv );
        newdiv = map = centerlonlat = projection = displayProjection = pointLayer = selectControl = popup = null;
      }
    };
  },
  {
    about:{
      name: "Popcorn OpenMap Plugin",
      version: "0.3",
      author: "@mapmeld",
      website: "mapadelsur.blogspot.com"
    },
    options:{
      start    : { elem: 'input', type: 'text', label: 'In'},
      end      : { elem: 'input', type: 'text', label: 'Out'},
      target   : 'map-container',
      type     : { elem: 'select', options:[ 'ROADMAP', 'SATELLITE', 'TERRAIN' ], label: 'Type' },
      zoom     : { elem: 'input', type: 'text', label: 'Zoom'},
      lat      : { elem: 'input', type: 'text', label: 'Lat'},
      lng      : { elem: 'input', type: 'text', label: 'Lng'},
      location : { elem: 'input', type: 'text', label: 'Location'},
      markers  : { elem: 'input', type: 'text', label: 'List Markers'}
    }
  });
}) ( Popcorn );
