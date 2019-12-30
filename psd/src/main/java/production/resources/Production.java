package production.resources;

import production.representations.Saying;

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

@Path("/departments")
@Produces(MediaType.APPLICATION_JSON)
public class Production {

    @GET
    public List<Saying> getAll() {
        //Pedir ao servidor todos os produtos disponiveis
        return new ArrayList<>();
    }

    @GET
    @Path("/{name}")
    public Response getProduction(@PathParam("name") String name){
        //if(!production.containsKey(name)){
        //    return Response.status(Response.Status.NOT_FOUND).build();
        //}
        //Production prod = get(name);
        //Colocar no Saying as informações. Depois mudar tambem o Saying
        Saying s = new Saying("name", "description");
        
        return Response.ok(s).build();
    }
}