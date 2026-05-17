import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix for default marker icon issues in React-Leaflet
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

let DefaultIcon = L.icon({
    iconUrl: icon,
    shadowUrl: iconShadow,
    iconSize: [25, 41],
    iconAnchor: [12, 41]
});

L.Marker.prototype.options.icon = DefaultIcon;

// Helper component to center map on new points
function ChangeView({ center }) {
    const map = useMap();
    map.setView(center, map.getZoom());
    return null;
}

const MapComponent = ({ analysisResult }) => {
    // Default Center: New Delhi, India
    const [center, setCenter] = useState([28.6139, 77.2090]);
    const [markers, setMarkers] = useState([]);
    
    // Geoapify Configuration
    const API_KEY = "fd16a56abda44693815d5aa0df2c9efc"; 
    const MAP_STYLE = "dark-matter-dark-grey"; // Military/Dark aesthetic
    const TILE_URL = `https://maps.geoapify.com/v1/tile/${MAP_STYLE}/{z}/{x}/{y}.png?apiKey=${API_KEY}`;

    useEffect(() => {
        if (analysisResult && analysisResult.entities) {
            const locEntities = analysisResult.entities.filter(e => e.type === 'LOC');
            
            // If AI provided coordinates, use them
            const newMarkers = [];
            let newCenter = null;

            locEntities.forEach(loc => {
                if (loc.lat && loc.lng) {
                    newMarkers.push({
                        position: [loc.lat, loc.lng],
                        text: loc.value,
                        threat: analysisResult.threat_score
                    });
                    newCenter = [loc.lat, loc.lng];
                } else {
                    console.log("No coords for:", loc.value);
                }
            });

            if (newMarkers.length > 0) {
                setMarkers(newMarkers);
                if (newCenter) setCenter(newCenter);
            }
        }
    }, [analysisResult]);

    return (
        <MapContainer center={center} zoom={5} scrollWheelZoom={true} style={{ height: '100%', width: '100%' }}>
            <TileLayer
                attribution='Powered by <a href="https://www.geoapify.com/" target="_blank">Geoapify</a> | &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                url={TILE_URL}
                className="map-tiles"
            />
            
            <ChangeView center={center} />

            {markers.map((marker, idx) => (
                <Marker key={idx} position={marker.position}>
                    <Popup>
                        <div className="text-black">
                            <strong>{marker.text}</strong><br/>
                            Threat: {(marker.threat * 100).toFixed(0)}%
                        </div>
                    </Popup>
                </Marker>
            ))}
        </MapContainer>
    );
};

export default MapComponent;
