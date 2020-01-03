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

@Path("/negociacoes")
@Produces(MediaType.APPLICATION_JSON)
public class Negociacoes{
    /*
    @GET
    public List<Saying> getAll() {
        //Pedir ao servidor todos os produtos disponiveis
        return new ArrayList<>();
    }
    */
    @GET
    @Path("/{name}")
    public Response getNegocios(@PathParam("name") String name){
        //Mudar o Saying pq n é so name e description        
        
        //Criar outro Saying para ter uma lista de String
        Saying s = new Saying("name", "description");
        
        return Response.ok(s).build();
    }
}