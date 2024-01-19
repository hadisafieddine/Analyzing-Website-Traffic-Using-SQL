-- 1
USE mavenfuzzyfactory;
SELECT
	MIN(DATE(website_sessions.created_at)) AS month_starting,
    COUNT(DISTINCT website_sessions.website_session_id) AS gsearch_sessions,
    COUNT(DISTINCT orders.order_id) AS orders

FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id

WHERE
	website_sessions.created_at < '2012-11-27'
    AND website_sessions.utm_source = 'gsearch'
    
GROUP BY MONTH(website_sessions.created_at);
-- 2
SELECT
	MIN(DATE(created_at)) AS month_starting,
    COUNT(DISTINCT website_session_id) AS total_gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS brand
    
FROM website_sessions
WHERE
	created_at < '2012-11-27'
    AND utm_source = 'gsearch'
GROUP BY
	MONTH(created_at);
    
-- 3
SELECT
	MIN(DATE(website_sessions.created_at)) AS month_starting,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS sessions_by_mobile,
    COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS sessions_by_desktop,
    COUNT(CASE WHEN device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS orders_by_mobile,
    COUNT(CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS orders_by_desktop
FROM website_sessions

	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id

WHERE
	website_sessions.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'

GROUP BY MONTH(website_sessions.created_at);
	
-- 4
SELECT
	MIN(DATE(created_at)) AS month_starting,
    COUNT(website_session_id) AS total_sessions,
    COUNT(CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS thru_gsearch,
    COUNT(CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS thru_bsearch
    
FROM website_sessions
WHERE
	created_at < '2012-11-27'
GROUP BY
	MONTH(created_at);

-- 5
SELECT
	MIN(DATE(website_sessions.created_at)) AS month_starting,
    COUNT(website_sessions.website_session_id) AS sessions,
    COUNT(orders.order_id) AS orders,
    COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS cvr

FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id

WHERE website_sessions.created_at < '2012-11-27'
GROUP BY MONTH(website_sessions.created_at);
-- 6
SELECT * FROM website_sessions;
SELECT * FROM website_pageviews;
CREATE TEMPORARY TABLE gsearch_nonbrand_sessions
SELECT
	website_sessions.created_at,
    website_sessions.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'

GROUP BY 	
	website_sessions.created_at,
    website_sessions.website_session_id,
	website_pageviews.website_pageview_id,
    website_pageviews.pageview_url;

CREATE TEMPORARY TABLE sessions_landing_home_or_lander1
SELECT DISTINCT
	created_at,
    website_session_id,
    MIN(website_pageview_id),
    pageview_url
FROM gsearch_nonbrand_sessions
WHERE
	(pageview_url) IN ('/home', '/lander-1')
GROUP BY 
	created_at,
    website_session_id,
    website_pageview_id,
    pageview_url;

CREATE TEMPORARY TABLE gsearch_nonbrand_home_lander1
SELECT
	gsearch_nonbrand_sessions.created_at,
    gsearch_nonbrand_sessions.website_session_id,
	gsearch_nonbrand_sessions.website_pageview_id,
    gsearch_nonbrand_sessions.pageview_url
FROM gsearch_nonbrand_sessions
	INNER JOIN sessions_landing_home_or_lander1
		ON sessions_landing_home_or_lander1.website_session_id = gsearch_nonbrand_sessions.website_session_id
GROUP BY
	gsearch_nonbrand_sessions.created_at,
    gsearch_nonbrand_sessions.website_session_id,
	gsearch_nonbrand_sessions.website_pageview_id,
    gsearch_nonbrand_sessions.pageview_url;

CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	website_session_id AS bounced_sessions
FROM gsearch_nonbrand_home_lander1
GROUP BY website_session_id
HAVING COUNT(website_pageview_id) = 1;
	
SELECT
	gsearch_nonbrand_home_lander1.pageview_url AS landing_page,
    COUNT(DISTINCT gsearch_nonbrand_home_lander1.website_session_id) AS total_sessions,
    COUNT(bounced_sessions.bounced_sessions) AS bounced_sessions,
    COUNT(bounced_sessions.bounced_sessions)/COUNT(DISTINCT gsearch_nonbrand_home_lander1.website_session_id) AS bounce_rate
FROM gsearch_nonbrand_home_lander1
LEFT JOIN bounced_sessions
	ON bounced_sessions.bounced_sessions = gsearch_nonbrand_home_lander1.website_session_id
WHERE (pageview_url) IN ('/home', '/lander-1')
GROUP BY gsearch_nonbrand_home_lander1.pageview_url;

CREATE TEMPORARY TABLE conv_rate
SELECT
	gsearch_nonbrand_home_lander1.pageview_url AS landing_page,
    COUNT(DISTINCT gsearch_nonbrand_home_lander1.website_session_id) AS total_sessions,
    COUNT(orders.order_id) AS orders,
    COUNT(orders.order_id)/COUNT(DISTINCT gsearch_nonbrand_home_lander1.website_session_id) AS CVR
FROM gsearch_nonbrand_home_lander1
LEFT JOIN orders
	ON orders.website_session_id = gsearch_nonbrand_home_lander1.website_session_id
WHERE (pageview_url) IN ('/home', '/lander-1')
GROUP BY gsearch_nonbrand_home_lander1.pageview_url;

SELECT * FROM conv_rate;
SELECT CVR - LAG(CVR) OVER(ORDER BY landing_page) AS increased_CVR FROM conv_rate;
SELECT 
	COUNT(website_session_id) * 0.0088 AS increase_in_orders

FROM website_sessions 
WHERE 
	created_at BETWEEN '2012-07-29' AND '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';
USE mavenfuzzyfactory;
-- 7

CREATE TEMPORARY TABLE nonbrand_gsearch_sessions;
SELECT 
	website_sessions.created_at,
    website_sessions.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    
GROUP BY 
	website_sessions.website_session_id,
    website_sessions.created_at,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url;

CREATE TEMPORARY TABLE landing_pages
SELECT
	nonbrand_gsearch_sessions.website_session_id,
    MIN(nonbrand_gsearch_sessions.website_pageview_id) AS landing_page,
    nonbrand_gsearch_sessions.pageview_url
FROM nonbrand_gsearch_sessions
LEFT JOIN website_pageviews
	ON website_pageviews.website_pageview_id = nonbrand_gsearch_sessions.website_pageview_id
WHERE nonbrand_gsearch_sessions.pageview_url IN ('/home','/lander-1')
GROUP BY nonbrand_gsearch_sessions.website_session_id,nonbrand_gsearch_sessions.pageview_url; 
SELECT * FROM landing_pages;

CREATE TEMPORARY TABLE landing_home;
SELECT
	website_session_id,
	pageview_url
FROM landing_pages
WHERE pageview_url = '/home';

CREATE TEMPORARY TABLE landing_lander1;
SELECT
	website_session_id,
	pageview_url
FROM landing_pages
WHERE pageview_url = '/lander-1';

CREATE TEMPORARY TABLE home_funnel_unsorted
SELECT
	nonbrand_gsearch_sessions.website_session_id,
    nonbrand_gsearch_sessions.website_pageview_id,
    nonbrand_gsearch_sessions.pageview_url,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_mrfuzzy,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/cart' THEN 1 ELSE 0 END AS to_cart,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/shipping' THEN 1 ELSE 0 END AS to_shipping,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/billing' THEN 1 ELSE 0 END AS to_billing,
	CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS order_complete
FROM nonbrand_gsearch_sessions
INNER JOIN landing_home
	ON landing_home.website_session_id = nonbrand_gsearch_sessions.website_session_id
GROUP BY 1,2,3;

CREATE TEMPORARY TABLE home_funnel_sorted
SELECT
	website_session_id,
    MAX(to_products) AS to_products,
    MAX(to_mrfuzzy) AS to_mrfuzzy,
    MAX(to_cart) AS to_cart,
    MAX(to_shipping) AS to_shipping,
    MAX(to_billing) AS to_billing,
    MAX(order_complete) AS order_complete
FROM home_funnel_unsorted
GROUP BY 1;

CREATE TEMPORARY TABLE lander1_funnel_unsorted
SELECT
	nonbrand_gsearch_sessions.website_session_id,
    nonbrand_gsearch_sessions.website_pageview_id,
    nonbrand_gsearch_sessions.pageview_url,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_mrfuzzy,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/cart' THEN 1 ELSE 0 END AS to_cart,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/shipping' THEN 1 ELSE 0 END AS to_shipping,
    CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/billing' THEN 1 ELSE 0 END AS to_billing,
	CASE WHEN nonbrand_gsearch_sessions.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS order_complete
FROM nonbrand_gsearch_sessions
INNER JOIN landing_lander1
	ON landing_lander1.website_session_id = nonbrand_gsearch_sessions.website_session_id
GROUP BY 1,2,3;

CREATE TEMPORARY TABLE lander1_funnel_sorted
SELECT
	website_session_id,
    MAX(to_products) AS to_products,
    MAX(to_mrfuzzy) AS to_mrfuzzy,
    MAX(to_cart) AS to_cart,
    MAX(to_shipping) AS to_shipping,
    MAX(to_billing) AS to_billing,
    MAX(order_complete) AS order_complete
FROM lander1_funnel_unsorted
GROUP BY 1;

CREATE TEMPORARY TABLE lander1_conversions
SELECT 
	'/lander-1' AS landing_page,
    COUNT(landing_lander1.website_session_id) AS sessions,
	SUM(to_products) AS to_products,
    SUM(to_mrfuzzy) AS to_mrfuzzy,
    SUM(to_cart) AS to_cart,
    SUM(to_shipping) AS to_shipping,
    SUM(to_billing) AS to_billing,
    SUM(order_complete) AS order_complete
FROM lander1_funnel_sorted
INNER JOIN landing_lander1
	ON landing_lander1.website_session_id = lander1_funnel_sorted.website_session_id
GROUP BY 1;

CREATE TEMPORARY TABLE home_conversions
SELECT 
	'/home' AS landing_page,
    COUNT(landing_home.website_session_id) AS sessions,
	SUM(to_products) AS to_products,
    SUM(to_mrfuzzy) AS to_mrfuzzy,
    SUM(to_cart) AS to_cart,
    SUM(to_shipping) AS to_shipping,
    SUM(to_billing) AS to_billing,
    SUM(order_complete) AS order_complete
FROM home_funnel_sorted
INNER JOIN landing_home
	ON landing_home.website_session_id = home_funnel_sorted.website_session_id
GROUP BY 1;


SELECT * FROM lander1_conversions
	UNION
SELECT * FROM home_conversions

