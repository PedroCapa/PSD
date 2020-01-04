package restinterface.resources;

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

@Path("/catalogo")
@Produces(MediaType.APPLICATION_JSON)
public class Catalogo {
    private String nome;
    private List<Object> collection;

    public Catalogo(String nome, List<Object> collection) {
        this.nome = nome;
        this.collection = collection;
    }

    public String getNome(){
        return this.nome;
    }

    public List<Object> getCollection(){
        return this.collection;
    }    
}