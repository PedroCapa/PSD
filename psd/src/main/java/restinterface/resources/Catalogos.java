package main.java.restinterface.resources;

import main.java.restinterface.representations.Prod;
import main.java.restinterface.representations.Neg;

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

@Path("/catalogos")
@Produces(MediaType.APPLICATION_JSON)
public class Catalogos{

    @GET
    @Path("/importador/{name}")
    public List<Neg> getImportador(@PathParam("name") String name){
        System.out.println("Pediu um pedido de um importador");
        List<Neg> n = new ArrayList<>();
        try{
            AskServer ask = new AskServer();
            List<Negocio> prod = ask.askServerNegocio(name, "imp");        
            
            for(Negocio neg: prod){
                n.add(new Neg(neg.getFab(), neg.getClient_offer(), neg.getProd(), neg.getPrice(), neg.getAmount()));
            }
        }
        catch(Exception e){
            System.out.println(e.getMessage());
        }
        finally{
            return n;
        }
    }

    @GET
    @Path("/produtor/{name}")
    public List<Prod> getProdutor(@PathParam("name") String name){
        System.out.println("Pediu um pedido de um produto");
        List<Prod> p = new ArrayList<>();
        try{
            AskServer ask = new AskServer();
            List<Produto> prod = ask.askServerProduto(name, "produtores");        
            
            System.out.println("Recebi tudo");

            for(Produto pro: prod){
                p.add(new Prod(pro.getProduct_name(), pro.getNegotiator_name(), pro.getMin(), 
                                                      pro.getMax(), pro.getPrice()));
            }
        }
        catch(Exception e){
            System.out.println(e.getMessage());
        }
        finally{
            return p;
        }
    }

    @GET
    @Path("/negocio/{name}")
    public List<Neg> getNegocio(@PathParam("name") String name){
        System.out.println("Pediu um pedido de um negocio");
        List<Neg> n = new ArrayList<>();
        try{
            AskServer ask = new AskServer();
            List<Negocio> prod = ask.askServerNegocio(name, "negotiations");        
            
            for(Negocio neg: prod){
                n.add(new Neg(neg.getFab(), neg.getClient_offer(), neg.getProd(), neg.getPrice(), neg.getAmount()));
            }
        }
        catch(Exception e){
            System.out.println(e.getMessage());
        }
        finally{
            return n;
        }
    }
}