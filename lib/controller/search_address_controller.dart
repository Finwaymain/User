import 'dart:convert';
import 'dart:io';
import 'package:finway/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_workers/utils/debouncer.dart';
import 'package:http/http.dart' as http;

class SearchAddressController extends GetxController {
  //for Choose your Rider

  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<SearchInfo> suggestionsList = <SearchInfo>[].obs;
  final debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  RxBool isSearch = false.obs;
  final Map<String, String> placeIdMap = {};

  Future<SearchInfo?> resolvePlaceDetails(SearchInfo suggestion) async {
    final description = suggestion.address?.name ?? '';
    final placeId = placeIdMap[description];
    if (placeId == null || placeId.isEmpty) return null;

    try {
      final detailsUri = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,address_components,formatted_address&key=${Constant.kGoogleApiKey}"
      );
      final response = await http.get(detailsUri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded != null && decoded['result'] != null) {
          final result = decoded['result'];
          final geometry = result['geometry'];
          if (geometry != null && geometry['location'] != null) {
            final double lat = (geometry['location']['lat'] as num).toDouble();
            final double lng = (geometry['location']['lng'] as num).toDouble();
            
            String? postcode;
            String? street;
            String? houseNumber;
            String? city;
            String? state;
            String? country;
            
            final addressComponents = result['address_components'] as List?;
            if (addressComponents != null) {
              for (var component in addressComponents) {
                final types = component['types'] as List?;
                if (types != null) {
                  if (types.contains('postal_code')) {
                    postcode = component['long_name']?.toString();
                  } else if (types.contains('route')) {
                    street = component['long_name']?.toString();
                  } else if (types.contains('street_number')) {
                    houseNumber = component['long_name']?.toString();
                  } else if (types.contains('locality')) {
                    city = component['long_name']?.toString();
                  } else if (types.contains('administrative_area_level_1')) {
                    state = component['long_name']?.toString();
                  } else if (types.contains('country')) {
                    country = component['long_name']?.toString();
                  }
                }
              }
            }
            
            final address = Address(
              name: result['formatted_address']?.toString() ?? description,
              street: street,
              housenumber: houseNumber,
              postcode: postcode,
              city: city,
              state: state,
              country: country,
            );
            
            return SearchInfo(
              point: GeoPoint(latitude: lat, longitude: lng),
              address: address,
            );
          }
        }
      }
    } catch (e) {
      print("Error resolving place details: $e");
    }
    return null;
  }

  fetchAddress(text) async {
    if (text.trim().isEmpty) return;
    print("fetchAddress => text: $text");
    isSearch.value = true;
    try {
      if (Constant.selectedMapType == 'google') {
        print("Using Google Places Autocomplete API...");
        final autocompleteUri = Uri.parse(
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(text)}&key=${Constant.kGoogleApiKey}&language=${Get.locale?.languageCode ?? 'en'}"
        );
        final response = await http.get(autocompleteUri);
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded != null && decoded['predictions'] != null) {
            final List predictions = decoded['predictions'];
            final List<SearchInfo> results = [];
            placeIdMap.clear();
            for (var item in predictions) {
              try {
                final String description = item['description'] ?? '';
                final String placeId = item['place_id'] ?? '';
                if (description.isNotEmpty && placeId.isNotEmpty) {
                  placeIdMap[description] = placeId;
                  results.add(SearchInfo(
                    point: GeoPoint(latitude: 0.0, longitude: 0.0),
                    address: Address(name: description),
                  ));
                }
              } catch (e) {
                print("Error parsing google prediction: $e");
              }
            }
            if (results.isNotEmpty) {
              suggestionsList.value = results;
              isSearch.value = false;
              return;
            }
          }
        }
      }


      // Fallback 1: Query Photon API directly using HTTP client with a standard User-Agent
      print("Fallback 1: Querying Photon API directly...");
      final photonUri = Uri.parse(
        "https://photon.komoot.io/api/?q=${Uri.encodeComponent(text)}&limit=5&lang=${Get.locale?.languageCode ?? 'en'}"
      );
      final photonResponse = await http.get(photonUri, headers: {
        'User-Agent': Platform.isAndroid ? 'com.cabme' : 'com.cabme.ios',
      });
      if (photonResponse.statusCode == 200) {
        final decoded = json.decode(photonResponse.body);
        if (decoded != null && decoded['features'] != null) {
          final List features = decoded['features'];
          final List<SearchInfo> results = [];
          for (var item in features) {
            try {
              final coordinates = item['geometry']['coordinates'];
              final props = item['properties'] ?? {};
              
              final double lon = (coordinates[0] as num).toDouble();
              final double lat = (coordinates[1] as num).toDouble();
              
              final String? name = props['name']?.toString();
              final String? street = props['street']?.toString();
              final String? houseNumber = props['housenumber']?.toString();
              final String? postcode = props['postcode']?.toString();
              final String? city = props['city']?.toString();
              final String? state = props['state']?.toString();
              final String? country = props['country']?.toString();
              
              final address = Address(
                name: name,
                street: street,
                housenumber: houseNumber,
                postcode: postcode,
                city: city,
                state: state,
                country: country,
              );
              
              results.add(SearchInfo(
                point: GeoPoint(latitude: lat, longitude: lon),
                address: address,
              ));
            } catch (parseError) {
              print("Error parsing photon item: $parseError");
            }
          }
          if (results.isNotEmpty) {
            suggestionsList.value = results;
            isSearch.value = false;
            return;
          }
        }
      }

      // Fallback 2: Query Nominatim Search API directly using HTTP client with a standard User-Agent
      print("Fallback 2: Querying Nominatim Search API directly...");
      final nominatimUri = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(text)}&format=json&limit=5&addressdetails=1"
      );
      final nominatimResponse = await http.get(nominatimUri, headers: {
        'User-Agent': Platform.isAndroid ? 'com.cabme' : 'com.cabme.ios',
      });
      if (nominatimResponse.statusCode == 200) {
        final List decoded = json.decode(nominatimResponse.body);
        final List<SearchInfo> results = [];
        for (var item in decoded) {
          try {
            final double lat = double.parse(item['lat'].toString());
            final double lon = double.parse(item['lon'].toString());
            final String displayName = item['display_name'] ?? '';
            final addrProps = item['address'] ?? {};
            
            final String? street = addrProps['road']?.toString();
            final String? houseNumber = addrProps['house_number']?.toString();
            final String? postcode = addrProps['postcode']?.toString();
            final String? city = (addrProps['city'] ?? addrProps['town'] ?? addrProps['village'] ?? addrProps['suburb'])?.toString();
            final String? state = addrProps['state']?.toString();
            final String? country = addrProps['country']?.toString();
            
            final address = Address(
              name: displayName,
              street: street,
              housenumber: houseNumber,
              postcode: postcode,
              city: city,
              state: state,
              country: country,
            );
            
            results.add(SearchInfo(
              point: GeoPoint(latitude: lat, longitude: lon),
              address: address,
            ));
          } catch (parseError) {
            print("Error parsing nominatim item: $parseError");
          }
        }
        if (results.isNotEmpty) {
          suggestionsList.value = results;
          isSearch.value = false;
          return;
        }
      }
      
      suggestionsList.clear();
    } catch (e) {
      print("fetchAddress => error: ${e.toString()}");
      suggestionsList.clear();
    } finally {
      isSearch.value = false;
    }
  }
}
