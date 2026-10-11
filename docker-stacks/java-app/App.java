import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

/** Tiny HTTP API (JDK built-in server, no dependencies) with a visit counter stored on a volume. */
public class App {

    private static final Path DATA_FILE =
            Path.of(System.getenv().getOrDefault("DATA_DIR", "/data"), "visits.txt");

    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);

        server.createContext("/health", exchange -> respond(exchange, "text/plain", "ok"));
        server.createContext("/", exchange -> {
            int visits = nextVisit();
            String host = InetAddress.getLocalHost().getHostName();
            respond(exchange, "application/json",
                    "{\"message\":\"Hello from Java\",\"visits\":" + visits + ",\"host\":\"" + host + "\"}");
        });

        server.start();
        System.out.println("Listening on port 8080");
    }

    private static synchronized int nextVisit() throws IOException {
        int visits = Files.exists(DATA_FILE) ? Integer.parseInt(Files.readString(DATA_FILE).trim()) + 1 : 1;
        Files.writeString(DATA_FILE, String.valueOf(visits));
        return visits;
    }

    private static void respond(HttpExchange exchange, String contentType, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.sendResponseHeaders(200, bytes.length);
        try (OutputStream out = exchange.getResponseBody()) {
            out.write(bytes);
        }
    }
}
