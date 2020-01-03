package restinterface.resources;

import restinterface.representations.Saying;

import com.google.common.base.Optional;

import javax.ws.rs.GET;
import javax.ws.rs.PUT;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.PathParam;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

@Path("/produtor")
@Produces(MediaType.APPLICATION_JSON)
public class Produtor {
    private String name;
    private List<Produto> productNames;

    public Produtor(String defaultName, List<Produto> productNames) {
        this.name = defaultName;
        this.productNames = productNames;
    }

    public String getName(){
        return this.name;
    }

    public List<Produto> getProductNames(){
        return this.productNames;
    }
}