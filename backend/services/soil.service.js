import axios from 'axios';

/**
 * SoilGrids WMS GetFeatureInfo üzerinden veri çekme fonksiyonu
 * REST API kapalıyken en kararlı yöntemdir.
 */
export const fetchSoilDataFromWMS = async (lat, lng, property) => {
    try {
        const url = `https://maps.isric.org/mapserv?map=/srv/projects/soilgrids-v2/maps/${property}.map`;
        
        const response = await axios.get(url, {
            params: {
                service: 'WMS',
                version: '1.3.0',
                request: 'GetFeatureInfo',
                layers: `${property}_0-5cm_mean`,
                query_layers: `${property}_0-5cm_mean`,
                i: 50,
                j: 50,
                width: 101,
                height: 101,
                crs: 'EPSG:4326',
                bbox: `${lat - 0.001},${lng - 0.001},${lat + 0.001},${lng + 0.001}`,
                info_format: 'application/json'
            },
            timeout: 5000
        });

        if (response.data && response.data.features && response.data.features.length > 0) {
            return response.data.features[0].properties['value_0'] || null;
        }
        return null;
    } catch (error) {
        console.error(`WMS Hatası (${property}):`, error.message);
        return null;
    }
};
